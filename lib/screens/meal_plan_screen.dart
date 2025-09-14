import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({Key? key}) : super(key: key);

  @override
  _MealPlanScreenState createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen>
    with TickerProviderStateMixin {
  bool _replacingMeal = false;
  bool _loading = true;
  Map<String, List<Map<String, dynamic>>> meals = {};

  final List<String> foodImages = const [
    "assets/images/foods/avena-frutos-rojos.png",
    "assets/images/foods/pollo-quinoa.png",
    "assets/images/foods/salmon-vegetables.png",
    "assets/images/foods/yogurt-nueces.png",
  ];

  final List<AnimationController> _controllers = [];
  final List<Animation<Offset>> _animations = [];

  @override
  void initState() {
    super.initState();
    _fetchMealPlan();
  }

  @override
  void dispose() {
    for (var controller in _controllers) controller.dispose();
    super.dispose();
  }

  void _setupAnimations(Map<String, List<Map<String, dynamic>>> parsedMeals) {
    _controllers.clear();
    _animations.clear();
    for (var mealList in parsedMeals.values) {
      for (int i = 0; i < mealList.length; i++) {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 800),
          vsync: this,
        );
        final animation = Tween<Offset>(
          begin: const Offset(-1.0, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
        _controllers.add(controller);
        _animations.add(animation);
      }
    }
  }

  Future<void> _fetchMealPlan() async {
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) {
        _showError('Sesión expirada. Inicia sesión de nuevo.');
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final url = Uri.parse('http://127.0.0.1:8000/ai/menus?tipo=diario');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        if (list.isEmpty) {
          setState(() {
            meals = {};
            _loading = false;
          });
          return;
        }

        list.sort((a, b) {
          final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
          final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
          return db.compareTo(da);
        });

        final latest = list.first;
        final menu = (latest['menu'] ?? {}) as Map<String, dynamic>;
        final Map<String, List<Map<String, dynamic>>> parsedMeals = {};

        menu.forEach((mealType, items) {
          parsedMeals[mealType.toString()] = (items as List).map((item) {
            final img = foodImages[Random().nextInt(foodImages.length)];
            final macros = item["macros"] ?? {};
            return {
              "id": item["id"],
              "planId": item["plan_id"],
              "name": item["nombre"] ?? "Comida",
              "cantidad": item["cantidad"] ?? "",
              "carbs": macros["carbohidratos_g"] ?? 0,
              "protein": macros["proteinas_g"] ?? 0,
              "fat": macros["grasas_g"] ?? 0,
              "calorias": item["calorias"] ?? 0,
              "completed": item["completed"] ?? false,
              "image": img,
            };
          }).toList();
        });

        // Solo actualizar meals, sin animaciones
        setState(() {
          meals = parsedMeals;
          _loading = false;
        });
      } else if (response.statusCode == 401) {
        _showError('Sesión no válida. Vuelve a iniciar sesión.');
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError('Error ${response.statusCode} al cargar el menú');
        setState(() => _loading = false);
      }
    } catch (e) {
      _showError('No se pudo conectar al servidor');
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleMealCompleted(Map<String, dynamic> meal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) {
        _showError('Sesión expirada. Inicia sesión de nuevo.');
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final id = meal['id'];
      final completed = !(meal['completed'] ?? false);
      final url = Uri.parse(
        'http://127.0.0.1:8000/ai/meals/$id/toggle?completed=$completed',
      );

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => meal['completed'] = data['completed']);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comida actualizada')));
      } else {
        _showError('Error ${response.statusCode} al actualizar comida');
      }
    } catch (e) {
      _showError('No se pudo conectar al servidor');
    }
  }

  Future<void> _replaceMeal(Map<String, dynamic> meal) async {
    setState(() => _replacingMeal = true); // mostrar overlay
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) {
        _showError('Sesión expirada. Inicia sesión de nuevo.');
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final planId = meal['planId'];
      final mealId = meal['id'];

      if (planId == null) {
        _showError("No se encontró el plan activo.");
        setState(() => _replacingMeal = false);
        return;
      }

      final url = Uri.parse(
        'http://127.0.0.1:8000/ai/menus/$planId/replace-meal/$mealId',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          meal["id"] = data["id"];
          meal["planId"] = data["plan_id"];
          meal["name"] = data["nombre"];
          meal["carbs"] = data["macros"]?["carbohidratos_g"] ?? 0;
          meal["protein"] = data["macros"]?["proteinas_g"] ?? 0;
          meal["fat"] = data["macros"]?["grasas_g"] ?? 0;
          meal["calorias"] = data["calorias"] ?? 0;
          meal["completed"] = data["completed"] ?? false;
        });
        // Animación de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✨ Tu plato ha sido transformado con magia! ✨"),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showError('Error ${response.statusCode} al reemplazar comida');
      }
    } catch (e) {
      print("🚨 Error en _replaceMeal: $e");
      _showError('No se pudo conectar al servidor');
    } finally {
      setState(() => _replacingMeal = false); // quitar overlay
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _generateDailyMenu() async {
    setState(() {
      _loading = true;
      _replacingMeal = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) {
        _showError('Sesión expirada. Inicia sesión de nuevo.');
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final url = Uri.parse('http://127.0.0.1:8000/ai/menus/generate');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'tipo': 'diario'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final menu = (data['menu'] ?? {}) as Map<String, dynamic>;
        final Map<String, List<Map<String, dynamic>>> parsedMeals = {};
        menu.forEach((mealType, items) {
          parsedMeals[mealType.toString()] = (items as List).map((item) {
            final img = foodImages[Random().nextInt(foodImages.length)];
            final macros = item["macros"] ?? {};
            return {
              "id": item["id"],
              "planId": item["plan_id"],
              "name": item["nombre"] ?? "Comida",
              "cantidad": item["cantidad"] ?? "",
              "carbs": macros["carbohidratos_g"] ?? 0,
              "protein": macros["proteinas_g"] ?? 0,
              "fat": macros["grasas_g"] ?? 0,
              "calorias": item["calorias"] ?? 0,
              "completed": item["completed"] ?? false,
              "image": img,
            };
          }).toList();
        });
        if (mounted) {
          setState(() {
            meals = parsedMeals;
          });

          // Solo aquí activamos las animaciones
          _setupAnimations(parsedMeals);

          // Lanzar animaciones secuenciales
          for (int i = 0; i < _controllers.length; i++) {
            Future.delayed(Duration(milliseconds: i * 2000), () {
              if (mounted) _controllers[i].forward();
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✨ Tu menú diario está listo! ✨")),
          );
        }
      } else {
        _showError('No se pudo generar el menú: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error generando el menú: $e');
    } finally {
      setState(() {
        _loading = false;
        _replacingMeal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int animationIndex = 0;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text(
              "Mi Plan – Diario",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: _fetchMealPlan,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _generateDailyMenu,
            icon: const Icon(Icons.auto_awesome),
            label: const Text("Generar menú"),
            backgroundColor: Colors.green[400],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : meals.isEmpty
              ? const Center(child: Text("No hay menú disponible"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: meals.entries.map((entry) {
                      final mealType = entry.key;
                      final mealList = entry.value;
                      final title = mealType.isNotEmpty
                          ? mealType[0].toUpperCase() + mealType.substring(1)
                          : mealType;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: mealList.map((meal) {
                              Widget mealWidget = _mealCard(meal);

                              if (animationIndex < _animations.length) {
                                final animation = _animations[animationIndex];
                                animationIndex++;
                                mealWidget = SlideTransition(
                                  position: animation,
                                  child: mealWidget,
                                );
                              }

                              return mealWidget;
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
        if (_replacingMeal)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(
                      'https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExcXZnc3Npcmw2dzVuMXduemF4YjFoYm04eHo1M2FoZjVpc21idzVtcyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9dHM/5oaWdgMNnLTrTSra4E/giphy.gif',
                      height: 150,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "🪄 Haciendo magia con tu menú...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.yellowAccent,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _mealCard(Map<String, dynamic> meal) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                meal["image"],
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal["name"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if ((meal["cantidad"] as String).isNotEmpty)
                    Text("Cantidad: ${meal["cantidad"]}"),
                  const SizedBox(height: 6),
                  Text(
                    "P: ${meal["protein"].toString()}g  C: ${meal["carbs"].toString()}g  F: ${meal["fat"].toString()}g",
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Calorías: ${meal["calorias"].toString()}",
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _replaceMeal(meal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Cambiar"),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(
                          meal['completed'] == true
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        onPressed: () => _toggleMealCompleted(meal),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
