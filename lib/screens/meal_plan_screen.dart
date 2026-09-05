import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal.dart';
import '../providers/meal_plan_provider.dart';
import '../providers/progress_provider.dart';

import '../widgets/replacing_overlay.dart';
import '../widgets/meals/meal_category_list.dart';
import '../widgets/modals/loading_ai_dialog.dart';

class MealPlanScreen extends StatefulWidget {
  final Function(int)? onTabSelected;

  const MealPlanScreen({super.key, this.onTabSelected});

  @override
  _MealPlanScreenState createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<Offset>> _animations = [];

  @override
  void initState() {
    super.initState();
    // Lanzamos la carga inicial en cuanto la pantalla termina de construirse
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // =========================================================================
  // 🧩 CONTROLADORES DE INTERFAZ (Hablan con el Provider)
  // =========================================================================

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
    // 1. 🌟 Levantamos el modal elegante ANTES de llamar al servidor
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
    await provider
        .generateDailyMenu(); // La app espera aquí mientras los textos giran

    if (!mounted) return;

    // 2. 🌟 Cerramos el modal en cuanto la IA nos devuelve el menú
    LoadingAiDialog.hide(context);

    // 3. Manejamos los resultados y pintamos la interfaz
    if (provider.profileError != null) {
      _showProfileIncompleteError(
        provider.profileError!.message,
        provider.profileError!.missingFields,
      );
    } else if (provider.errorMessage != null) {
      _showSnackBar(provider.errorMessage!);
    } else {
      _showSnackBar("Menú generado correctamente");
      _setupAnimations(provider.meals);
    }
  }

  Future<void> _handleReplace(String type, Meal meal) async {
    final provider = context.read<MealPlanProvider>();
    await provider.replaceMeal(type, meal);

    if (provider.errorMessage != null && mounted) {
      _showSnackBar(provider.errorMessage!);
    }
  }

  Future<void> _handleToggleCompleted(String type, Meal meal) async {
    final provider = context.read<MealPlanProvider>();
    await provider.toggleMealCompleted(type, meal);

    if (provider.errorMessage != null && mounted) {
      _showSnackBar(provider.errorMessage!);
    } else if (mounted) {
      // Sincronizamos el cerebro central
      context.read<ProgressProvider>().fetchProgress(silent: true);
    }
  }

  // =========================================================================
  // 🎬 ANIMACIONES
  // =========================================================================

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

  // =========================================================================
  // 🎨 UI HELPERS
  // =========================================================================

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showProfileIncompleteError(String message, List<String> missingFields) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Perfil incompleto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 10),
            const Text("Campos faltantes:"),
            const SizedBox(height: 5),
            ...missingFields.map((f) => Text("• $f")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              if (widget.onTabSelected != null) widget.onTabSelected!(3);
            },
            child: const Text(
              "Completar perfil",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 HELPER BLINDADO: Orden cronológico estricto para el Menú
  int _getCategoryOrder(String category) {
    final t = category.toLowerCase().trim();
    if (t.contains('desayuno') || t.contains('breakfast')) return 10;
    if (t.contains('media mañana') || t.contains('mañana')) return 20;
    if (t.contains('comida') || t.contains('almuerzo') || t.contains('lunch'))
      return 30;
    if (t.contains('merienda') || t.contains('snack') || t.contains('tarde'))
      return 40;
    if (t.contains('cena') || t.contains('dinner')) return 50;
    return 60;
  }

  // =========================================================================
  // 📱 METODO BUILD PRINCIPAL
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final planProvider = context.watch<MealPlanProvider>();

    // Lógica Soft Landing
    final double consumidas = progressProvider.caloriasConsumidas;
    final double meta = progressProvider.caloriasObjetivoHoy;
    final bool isCalorieLimitReached = meta > 0 && consumidas >= meta;

    // Sincronización entre providers
    if (progressProvider.planNeedsRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchData(isSilent: true);
          context.read<ProgressProvider>().setPlanNeedsRefresh(false);
        }
      });
    }

    int currentAnimationIndex = 0;

    // 🌟 EL FIX: Ordenamos las categorías del menú de forma estricta ANTES de pintarlas
    final sortedMealEntries = planProvider.meals.entries.toList();
    sortedMealEntries.sort(
      (a, b) => _getCategoryOrder(a.key).compareTo(_getCategoryOrder(b.key)),
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
              : sortedMealEntries
                    .isEmpty // 🚀 Usamos la lista ordenada aquí
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  // 🔥 Cuidado con el padding bottom para que no te pase el problema del último elemento cortado
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // 🚀 Usamos la lista ORDENADA en lugar del mapa crudo
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
        if (planProvider.isReplacingMeal) const ReplacingOverlay(),
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
