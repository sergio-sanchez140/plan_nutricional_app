import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal.dart';
import '../providers/meal_plan_provider.dart';
import '../providers/progress_provider.dart';
import '../utils/meal_sorter.dart';

import '../widgets/meals/meal_category_list.dart';
import '../widgets/modals/loading_ai_dialog.dart';
import '../widgets/modals/high_demand_alert.dart';
import '../widgets/modals/profile_incomplete_alert.dart';

class MealPlanScreen extends StatefulWidget {
  final Function(int)? onTabSelected;

  const MealPlanScreen({super.key, this.onTabSelected});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<Offset>> _animations = [];

  late ProgressProvider _progressProvider;

  @override
  void initState() {
    super.initState();

    // 🌟 ARQUITECTURA LIMPIA: Escuchamos eventos fuera del método build
    _progressProvider = context.read<ProgressProvider>();
    _progressProvider.addListener(_onProgressChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _progressProvider.removeListener(_onProgressChanged);
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // 🌟 Listener seguro para recargas en segundo plano
  void _onProgressChanged() {
    if (_progressProvider.planNeedsRefresh && mounted) {
      _fetchData(isSilent: true);
      _progressProvider.setPlanNeedsRefresh(false);
    }
  }

  Future<void> _fetchData({bool isSilent = false}) async {
    final provider = context.read<MealPlanProvider>();
    await provider.fetchMealPlan(isSilent: isSilent);

    if (provider.errorMessage != null && mounted && !isSilent) {
      _showSnackBar(provider.errorMessage!);
    } else if (mounted && !isSilent) {
      _setupAnimations(provider.meals);
    }
  }

  Future<void> _generateMenu() async {
    LoadingAiDialog.show(
      context,
      title: "Creando tu menú ideal",
      texts: [
        "Analizando tu perfil y objetivos...",
        "Calculando tus macros exactos...",
        "Diseñando recetas deliciosas...",
        "Ajustando las porciones...",
      ],
    );

    final provider = context.read<MealPlanProvider>();
    await provider.generateDailyMenu();

    if (!mounted) return;
    LoadingAiDialog.hide(context);

    if (provider.profileError != null) {
      ProfileIncompleteAlert.show(
        context: context,
        message: provider.profileError!.message,
        missingFields: provider.profileError!.missingFields,
        onTabSelected: widget.onTabSelected,
      );
    } else if (provider.meals.isEmpty) {
      HighDemandAlert.show(context);
    } else if (provider.errorMessage != null) {
      _showSnackBar(provider.errorMessage!);
    } else {
      _showSnackBar("Menú generado correctamente");
      _setupAnimations(provider.meals);
    }
  }

  Future<void> _handleReplace(String type, Meal meal) async {
    // 🌟 1. Levantamos el modal premium ANTES de llamar al servidor
    LoadingAiDialog.show(
      context,
      title: "Buscando alternativas",
      texts: [
        "Buscando opciones similares...",
        "Calculando equivalencias nutricionales...",
        "Ajustando nuevas porciones...",
        "¡Preparando la receta!",
      ],
    );

    final provider = context.read<MealPlanProvider>();
    await provider.replaceMeal(type, meal);

    if (!mounted) return;

    // 🌟 2. Cerramos el modal en cuanto la IA nos devuelve el nuevo plato
    LoadingAiDialog.hide(context);

    // 3. Manejamos los errores si los hay
    if (provider.errorMessage != null) {
      _showSnackBar(provider.errorMessage!);
    }
  }

  Future<void> _handleToggleCompleted(String type, Meal meal) async {
    final provider = context.read<MealPlanProvider>();
    await provider.toggleMealCompleted(type, meal);
    if (provider.errorMessage != null && mounted) {
      _showSnackBar(provider.errorMessage!);
    } else if (mounted) {
      context.read<ProgressProvider>().fetchProgress(silent: true);
    }
  }

  void _setupAnimations(Map<String, List<Meal>> meals) {
    for (final c in _controllers) c.dispose();
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final planProvider = context.watch<MealPlanProvider>();

    final double consumidas = progressProvider.caloriasConsumidas;
    final double meta = progressProvider.caloriasObjetivoHoy;
    final bool isCalorieLimitReached = meta > 0 && consumidas >= meta;

    int currentAnimationIndex = 0;

    final sortedMealEntries = planProvider.meals.entries.toList();
    sortedMealEntries.sort(
      (a, b) => MealSorter.getCategoryOrder(
        a.key,
      ).compareTo(MealSorter.getCategoryOrder(b.key)),
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[50],
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
                onPressed: _fetchData,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _generateMenu,
            icon: const Icon(Icons.auto_awesome),
            label: const Text("Generar menú"),
            backgroundColor: Colors.green,
          ),
          body: planProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )
              : sortedMealEntries.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sortedMealEntries.map((entry) {
                        final widgetList = MealCategoryList(
                          categoryName: entry.key,
                          meals: entry.value,
                          isCalorieLimitReached: isCalorieLimitReached,
                          onReplace: (meal) => _handleReplace(entry.key, meal),
                          onToggleCompleted: (meal) =>
                              _handleToggleCompleted(entry.key, meal),
                          animations: _animations,
                          startingAnimationIndex: currentAnimationIndex,
                        );
                        currentAnimationIndex += entry.value.length;
                        return widgetList;
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No hay menú disponible",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
