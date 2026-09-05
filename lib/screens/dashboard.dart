// Archivo: lib/screens/dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/dashboard_service.dart';
import '../providers/progress_provider.dart';
import '../screens/history_screen.dart';

// Componentes del Dashboard
import '../widgets/dashboard/profile_warning_card.dart';
import '../widgets/dashboard/dashboard_quick_actions.dart';
import '../widgets/ai_recommendation_card.dart';
import '../widgets/calories_summary_card.dart';
import '../widgets/meals_history_card.dart'; // <-- Nuestro nuevo súper-componente
import '../widgets/common/friendly_error_state.dart';
import '../widgets/modals/add_menu_bottom_sheet.dart';
import '../utils/ai_meal_flow.dart';
import '../utils/meal_sorter.dart';

class Dashboard extends StatefulWidget {
  final Function(int)? onTabSelected;

  const Dashboard({super.key, this.onTabSelected});

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  bool _hasError = false;
  Map<String, dynamic>? userData;
  bool _loading = true;
  bool perfilIncompleto = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    _fetchInitialData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData({bool isSilent = false}) async {
    if (!isSilent) setState(() => _loading = true);

    try {
      await context.read<ProgressProvider>().fetchProgress(silent: isSilent);
      final dataUsuario = await DashboardService.getUserData();

      DashboardService.syncNotifications();

      if (mounted) {
        setState(() {
          userData = dataUsuario;
          perfilIncompleto = _checkPerfilIncompleto(dataUsuario);
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted && !isSilent) setState(() => _loading = false);
    }
  }

  bool _checkPerfilIncompleto(Map<String, dynamic> data) {
    return data["edad"] == null ||
        data["peso"] == null ||
        data["altura"] == null ||
        data["genero"] == null ||
        data["nivel_actividad"] == null ||
        data["objetivo"] == null;
  }

  // =========================================================================
  // 🧩 MÉTODOS UI Y ACCIONES
  // =========================================================================
  Future<void> _handleAddMenuAction() async {
    final result = await AddMenuBottomSheet.show(context);
    if (!mounted || result == null) return;

    if (result == 'scanner') {
      // 🌟 LE PASAMOS isExtra: true
      await AiMealFlow.startCameraFlow(context, isExtra: true);
    } else if (result == 'manual') {
      await AiMealFlow.startManualFlow(context);
    }
  }

  // =========================================================================
  // 📱 INTERFAZ PRINCIPAL
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: FriendlyErrorState(
          onRetry: () => _fetchInitialData(isSilent: false),
        ),
      );
    }

    final progressProvider = context.watch<ProgressProvider>();
    final nombre = userData?['nombre'] ?? "Usuario";

    if (progressProvider.profileNeedsRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchInitialData(isSilent: true);
          context.read<ProgressProvider>().setProfileNeedsRefresh(false);
        }
      });
    }

    // Lógica UX de Calorías
    final double caloriasMeta = progressProvider.caloriasObjetivoHoy;
    final bool isCalorieLimitReached =
        caloriasMeta > 0 && progressProvider.caloriasConsumidas >= caloriasMeta;
    // 🌟 1. Extraemos y ORDENAMOS los turnos pendientes cronológicamente
    final List<String> turnosPendientes =
        List<String>.from(progressProvider.turnosPendientes)..sort(
          (a, b) => MealSorter.getCategoryOrder(
            a,
          ).compareTo(MealSorter.getCategoryOrder(b)),
        );

    // 🌟 2. Extraemos y ORDENAMOS el historial completado cronológicamente
    final List<String> historialOrdenado =
        List<String>.from(progressProvider.historialConsumo)..sort(
          (a, b) => MealSorter.getCategoryOrder(
            a,
          ).compareTo(MealSorter.getCategoryOrder(b)),
        );
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "¡Hola, $nombre! 🌟",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddMenuAction,
        backgroundColor: Colors.black87, // Un negro elegante estilo Apple
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
        label: const Text(
          "Extra",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchInitialData(isSilent: true),
        color: Colors.green,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Avisos
              if (perfilIncompleto)
                ProfileWarningCard(onTabSelected: widget.onTabSelected),

              // 2. Resumen de Calorías
              CaloriesSummaryCard(
                consumidas: progressProvider.caloriasConsumidas,
                meta: caloriasMeta,
                macros: progressProvider.macrosConsumidos,
                onTapHistory: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 🌟 3. EL TIMELINE UNIFICADO (Historial + Pendientes)
              if (progressProvider.historialConsumo.isNotEmpty ||
                  turnosPendientes.isNotEmpty) ...[
                MealsHistoryCard(
                  historial: historialOrdenado,
                  turnosPendientes: turnosPendientes,
                  isCalorieLimitReached: isCalorieLimitReached,
                  // 🌟 LA MAGIA: Al tocar un turno pendiente, saltamos al Tab de Menú
                  onPendingMealTap: (turno) {
                    if (widget.onTabSelected != null) {
                      widget.onTabSelected!(
                        1,
                      ); // 👈 Asumiendo que el index 1 es "Mi Plan"
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],

              // 4. Recomendaciones IA
              AIRecommendationCard(animation: _slideAnimation),
              const SizedBox(height: 24),

              // 5. Acciones Rápidas
              DashboardQuickActions(onTabSelected: widget.onTabSelected),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
