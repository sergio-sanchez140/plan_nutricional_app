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

class _MealPlanScreenState extends State<MealPlanScreen> {
  Map<String, List<Map<String, dynamic>>> meals = {};
  bool _loading = true;

  // Imágenes disponibles en assets
  final List<String> foodImages = const [
    "assets/images/foods/avena-frutos-rojos.png",
    "assets/images/foods/pollo-quinoa.png",
    "assets/images/foods/salmon-vegetables.png",
    "assets/images/foods/yogurt-nueces.png",
  ];

  @override
  void initState() {
    super.initState();
    _fetchMealPlan();
  }

  Future<void> _fetchMealPlan() async {
    try {
      setState(() => _loading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        _showError('Sesión expirada. Inicia sesión de nuevo.');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
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
            return {
              "id":
                  item["id"] ??
                  Random().nextInt(10000), // id necesario para PATCH
              "name": item["nombre"] ?? item["alimento"] ?? "Comida",
              "cantidad": item["cantidad"] ?? "",
              "carbs": item["carbohidratos"] ?? item["carbohidratos_g"] ?? 0,
              "protein":
                  item["proteínas"] ??
                  item["proteinas_g"] ??
                  item["proteina"] ??
                  0,
              "fat": item["grasas"] ?? 0,
              "image": img,
            };
          }).toList();
        });

        if (mounted) {
          setState(() {
            meals = parsedMeals;
            _loading = false;
          });
        }
      } else if (response.statusCode == 401) {
        _showError('Sesión no válida. Vuelve a iniciar sesión.');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
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
        setState(() {
          // Actualizamos con el valor real que devuelve el backend
          meal['completed'] = data['completed'];
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Comida actualizada')));
      } else {
        _showError('Error ${response.statusCode} al actualizar comida');
      }
    } catch (e) {
      _showError('No se pudo conectar al servidor');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Mi Plan – Diario",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                        children: mealList
                            .map((meal) => _mealCard(meal))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              ),
            ),
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
                    "P: ${meal["protein"]}g  C: ${meal["carbs"]}g  F: ${meal["fat"]}g",
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Cambiar comida
                        },
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
