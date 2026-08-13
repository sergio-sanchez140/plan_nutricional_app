import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../services/meal_plan_service.dart';
import '../widgets/meal_card.dart';
import '../widgets/replacing_overlay.dart';
import '../errors/profile_incomplete_exception.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({Key? key}) : super(key: key);

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
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
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _setupAnimations() {
    for (final c in _controllers) {
      c.dispose();
    }

    _controllers.clear();
    _animations.clear();

    for (final mealList in meals.values) {
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

  Future<void> _fetchMealPlan() async {
    print("🔥 FETCH MEAL PLAN START");

    setState(() => _loading = true);

    try {
      print("➡️ llamando service");

      final fetched = await _service.fetchMealPlan();

      print("✅ respuesta recibida: $fetched");

      setState(() {
        meals = fetched;
        _loading = false;
      });

      _setupAnimations();
    } catch (e, stack) {
      print("❌ ERROR FETCH MEAL PLAN: $e");
      print(stack);

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

    try {
      final generated = await _service.generateDailyMenu();

      setState(() {
        meals = generated;
        _loading = false;
        _replacingMeal = false;
      });

      _setupAnimations();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menú generado correctamente")),
      );
    } on ProfileIncompleteException catch (e) {
      setState(() {
        _loading = false;
        _replacingMeal = false;
      });

      _showProfileIncompleteError(e);
    } catch (e) {
      setState(() {
        _loading = false;
        _replacingMeal = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _replaceMeal(String type, Meal meal) async {
    setState(() => _replacingMeal = true);

    try {
      final newMeal = await _service.replaceMeal(meal);

      setState(() {
        final index = meals[type]?.indexWhere((m) => m.id == meal.id);

        if (index != null && index != -1) {
          meals[type]![index] = newMeal;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al reemplazar: $e')));
    } finally {
      setState(() => _replacingMeal = false);
    }
  }

  Future<void> _toggleMealCompleted(String type, Meal meal) async {
    try {
      final updated = await _service.toggleMealCompleted(meal);

      setState(() {
        final index = meals[type]?.indexWhere((m) => m.id == meal.id);

        if (index != null && index != -1) {
          meals[type]![index] = updated;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    }
  }

  void _showProfileIncompleteError(ProfileIncompleteException e) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("Perfil incompleto"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.message),
              const SizedBox(height: 10),
              const Text("Campos faltantes:"),
              const SizedBox(height: 5),
              ...e.missingFields.map((f) => Text("• $f")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.pushNamed(
                  context,
                  '/profileSetup',
                  arguments: {"missing_fields": e.missingFields},
                );
              },
              child: const Text("Completar perfil"),
            ),
          ],
        );
      },
    );
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
            backgroundColor: Colors.green,
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
                              Widget card = MealCard(
                                meal: meal,
                                onReplace: () => _replaceMeal(type, meal),
                                onToggleCompleted: () =>
                                    _toggleMealCompleted(type, meal),
                              );

                              if (animationIndex < _animations.length) {
                                card = SlideTransition(
                                  position: _animations[animationIndex],
                                  child: card,
                                );
                                animationIndex++;
                              }

                              return card;
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
