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

// Modales y Flujos
import '../widgets/modals/add_menu_bottom_sheet.dart';
import '../widgets/modals/ai_result_bottom_sheet.dart';
import '../widgets/free_intake_sheet.dart';
import '../utils/ai_meal_flow.dart';

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
      await AiMealFlow.startCameraFlow(context);
    } else if (result == 'manual') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FreeIntakeSheet(
            onSuccess: (iaData) async {
              if (!mounted) return;
              final turnosPendientes = context
                  .read<ProgressProvider>()
                  .turnosPendientes;

              final modalResult = await AiResultBottomSheet.show(
                context: context,
                data: iaData,
                intentosRestantes: 0,
                turnosPendientes: turnosPendientes,
              );

              if (modalResult != null && modalResult['action'] == 'confirm') {
                if (!mounted) return;
                await AiMealFlow.guardarPlatoAnalizado(
                  context,
                  iaData,
                  modalResult['resoluciones'],
                );
              }
            },
          ),
        ),
      );
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

    // Lógica UX de Calorías
    final double caloriasMeta = progressProvider.caloriasObjetivoHoy;
    final bool isCalorieLimitReached =
        caloriasMeta > 0 && progressProvider.caloriasConsumidas >= caloriasMeta;
    final List<String> turnosPendientes = List<String>.from(
      progressProvider.turnosPendientes,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddMenuAction,
        backgroundColor: Colors.green.shade600,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
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
                  historial: List<String>.from(
                    progressProvider.historialConsumo,
                  ),
                  turnosPendientes: turnosPendientes,
                  isCalorieLimitReached: isCalorieLimitReached,
                  onAddAction: _handleAddMenuAction,
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
