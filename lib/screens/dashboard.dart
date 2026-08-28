// Archivo: lib/screens/dashboard.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plan_nutricional_app/screens/history_screen.dart';
import 'package:plan_nutricional_app/services/notification_service.dart';
import 'package:provider/provider.dart';

import '../services/dashboard_service.dart';
import '../providers/progress_provider.dart';

import '../widgets/dashboard/profile_warning_card.dart';
import '../widgets/dashboard/dashboard_quick_actions.dart';
import '../widgets/ai_recommendation_card.dart';
import '../widgets/calories_summary_card.dart';
import '../widgets/free_intake_sheet.dart';
import '../widgets/meals_history_card.dart';

// Modales separados
import '../widgets/modals/add_menu_bottom_sheet.dart';
import '../widgets/modals/ai_result_bottom_sheet.dart';
import '../widgets/modals/loading_ai_dialog.dart';
import '../widgets/modals/photo_confirmation_dialog.dart';
import '../widgets/modals/recalculating_dialog.dart';

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

    // Carga inicial completa (con pantalla de carga)
    _fetchInitialData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🚀 REFACTOR: Añadimos isSilent para no poner la pantalla en blanco al recargar
  Future<void> _fetchInitialData({bool isSilent = false}) async {
    if (!isSilent) setState(() => _loading = true);

    try {
      // 1. Cargamos progreso al cerebro
      await context.read<ProgressProvider>().fetchProgress(silent: isSilent);
      // 2. Cargamos datos de usuario
      final dataUsuario = await DashboardService.getUserData();

      // 🌟 3. SINCRONIZAMOS LAS ALARMAS DE IA EN SEGUNDO PLANO
      DashboardService.syncNotifications();

      if (mounted) {
        setState(() {
          userData = dataUsuario;
          perfilIncompleto = _checkPerfilIncompleto(dataUsuario);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Error al cargar datos"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted && !isSilent) setState(() => _loading = false);
    }
  }

  // =========================================================================
  // 🧩 MÉTODOS UI Y ACCIONES
  // =========================================================================

  Future<void> _handleAddMenuAction() async {
    final result = await AddMenuBottomSheet.show(context);
    if (!mounted || result == null) return;

    if (result == 'scanner') {
      // 🚀 Llamada limpia a la nueva clase
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
                // 🚀 Llamamos a la lógica pública de guardado desde el modo manual
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

  bool _checkPerfilIncompleto(Map<String, dynamic> data) {
    return data["edad"] == null ||
        data["peso"] == null ||
        data["altura"] == null ||
        data["genero"] == null ||
        data["nivel_actividad"] == null ||
        data["objetivo"] == null;
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga completa (Solo al abrir la app la primera vez)
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    // 🚀 NOS SUSCRIBIMOS AL CEREBRO CENTRAL
    final progressProvider = context.watch<ProgressProvider>();
    final nombre = userData?['nombre'] ?? "Usuario";
    // 🌟 AHORA SÍ: Leemos la meta congelada del día desde el Provider
    final double caloriasMeta = progressProvider.caloriasObjetivoHoy;

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
        // 🚀 REFACTOR: Recarga silenciosa al tirar para abajo. El icono de RefreshIndicator ya hace de loading
        onRefresh: () => _fetchInitialData(isSilent: true),
        color: Colors.green,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (perfilIncompleto)
                ProfileWarningCard(onTabSelected: widget.onTabSelected),

              // 🚀 1. Llamada limpia a la tarjeta con su nueva propiedad
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
              const SizedBox(
                height: 20,
              ), // Y seguimos directamente con el historial o recomendaciones

              if (progressProvider.historialConsumo.isNotEmpty) ...[
                MealsHistoryCard(historial: progressProvider.historialConsumo),
                const SizedBox(height: 20),
              ],

              AIRecommendationCard(animation: _slideAnimation),
              const SizedBox(height: 24),

              DashboardQuickActions(onTabSelected: widget.onTabSelected),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
