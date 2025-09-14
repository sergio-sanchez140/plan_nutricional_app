import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';
import '../services/meal_plan_service.dart';
import '../widgets/meal_card.dart';
import '../widgets/replacing_overlay.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({Key? key}) : super(key: key);

  @override
  _MealPlanScreenState createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  bool _replacingMeal = false;
  Map<String, List<Meal>> meals = {};
  final List<String> foodImages = [
    "assets/images/foods/avena-frutos-rojos.png",
    "assets/images/foods/pollo-quinoa.png",
    "assets/images/foods/salmon-vegetables.png",
    "assets/images/foods/yogurt-nueces.png",
  ];

  late MealPlanService _service;
  final List<AnimationController> _controllers = [];
  final List<Animation<Offset>> _animations = [];

  @override
  void initState() {
    super.initState();
    _service = MealPlanService(foodImages);
    _fetchMealPlan();
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _controllers.clear();
    _animations.clear();
    for (var mealList in meals.values) {
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
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return null;
    }
    return token;
  }

  Future<void> _fetchMealPlan() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) return;

    try {
      final fetched = await _service.fetchMealPlan(token);
      setState(() {
        meals = fetched;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar: $e')));
    }
  }

  Future<void> _generateDailyMenu() async {
    setState(() {
      _loading = true;
      _replacingMeal = true;
    });
    final token = await _getToken();
    if (token == null) return;

    try {
      final generated = await _service.generateDailyMenu(token);
      setState(() {
        meals = generated;
      });
      _setupAnimations();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✨ Menú listo!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _loading = false;
        _replacingMeal = false;
      });
    }
  }

  // Aquí puedes agregar _replaceMeal y _toggleMealCompleted de manera similar usando _service

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
                      final type = entry.key;
                      final list = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type[0].toUpperCase() + type.substring(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: list.map((meal) {
                              Widget widget = MealCard(
                                meal: meal,
                                onReplace: () async {
                                  setState(() => _replacingMeal = true);
                                  final token = await _getToken();
                                  if (token == null) return;
                                  try {
                                    final newMeal = await _service.replaceMeal(
                                      token,
                                      meal,
                                    );
                                    setState(() {
                                      // Reemplazar meal en la lista actual
                                      final index = meals[type]!.indexOf(meal);
                                      meals[type]![index] = newMeal;
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error al reemplazar: $e',
                                        ),
                                      ),
                                    );
                                  } finally {
                                    setState(() => _replacingMeal = false);
                                  }
                                },
                                onToggleCompleted: () async {
                                  final token = await _getToken();
                                  if (token == null) return;
                                  try {
                                    final updatedMeal = await _service
                                        .toggleMealCompleted(token, meal);
                                    setState(() {
                                      final index = meals[type]!.indexOf(meal);
                                      meals[type]![index] = updatedMeal;
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error al actualizar: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                              if (animationIndex < _animations.length) {
                                widget = SlideTransition(
                                  position: _animations[animationIndex],
                                  child: widget,
                                );
                                animationIndex++;
                              }
                              return widget;
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
        if (_replacingMeal) const ReplacingOverlay(),
      ],
    );
  }
}
