// Archivo: lib/screens/dashboard.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  int _intentosVision = 3;
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

      if (mounted) {
        setState(() {
          userData = dataUsuario;
          perfilIncompleto = _checkPerfilIncompleto(dataUsuario);
        });
      }
    } catch (e) {
      _showMessage("Error al cargar datos", isError: true);
    } finally {
      if (mounted && !isSilent) setState(() => _loading = false);
    }
  }

  // =========================================================================
  // 📸 LÓGICA DE IA Y GUARDADO
  // =========================================================================

  Future<void> _analyzeFood({bool esReintento = false}) async {
    if (!esReintento) _intentosVision = 3;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final imageBytes = await image.readAsBytes();
    if (!mounted) return;

    final bool? confirmado = await PhotoConfirmationDialog.show(
      context,
      imageBytes,
    );

    if (confirmado == true) {
      _sendPhotoToBackend(image, esReintento);
    } else if (confirmado == false) {
      _analyzeFood(esReintento: esReintento);
    }
  }

  Future<void> _sendPhotoToBackend(XFile image, bool esReintento) async {
    LoadingAiDialog.show(context);
    try {
      final data = await DashboardService.analyzeVision(image);
      if (mounted) LoadingAiDialog.hide(context);

      if (mounted) {
        // 🚀 FIX: Leemos el provider con context.read() porque no estamos en el build()
        final turnosPendientes = context
            .read<ProgressProvider>()
            .turnosPendientes;

        final result = await AiResultBottomSheet.show(
          context: context,
          data: data,
          intentosRestantes: _intentosVision - 1,
          turnosPendientes: turnosPendientes, // Usamos la variable local
        );

        if (result != null) {
          final String action = result['action'] ?? '';
          if (action == 'confirm') {
            await _guardarPlatoAnalizado(data, result['resoluciones']);
          } else if (action == 'retry' && _intentosVision > 1) {
            _intentosVision--;
            _analyzeFood(esReintento: true);
          }
        }
      }
    } catch (e) {
      if (mounted) LoadingAiDialog.hide(context);
      _showMessage(
        'Ups: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    }
  }

  Future<void> _guardarPlatoAnalizado(
    Map<String, dynamic> data,
    dynamic resolucionesMap,
  ) async {
    RecalculatingDialog.show(context);

    try {
      List<Map<String, String>> listaResoluciones = [];
      if (resolucionesMap != null) {
        final map = resolucionesMap as Map<String, String>;
        listaResoluciones = map.entries
            .map((e) => {"turno": e.key, "estado": e.value})
            .toList();
      }

      await DashboardService.saveIntake(
        data,
        resolucionPendientes: listaResoluciones,
      );

      if (!mounted) return;

      await context.read<ProgressProvider>().fetchProgress(silent: true);
      context.read<ProgressProvider>().setPlanNeedsRefresh(true);

      RecalculatingDialog.hide(context);

      _showMessage('¡Plan recalculado con éxito! 🚀');
    } catch (e) {
      if (!mounted) return;

      RecalculatingDialog.hide(context);

      _showMessage('No se pudo guardar la comida', isError: true);
    }
  }

  // =========================================================================
  // 🧩 MÉTODOS UI Y ACCIONES
  // =========================================================================

  Future<void> _handleAddMenuAction() async {
    final result = await AddMenuBottomSheet.show(context);
    if (!mounted || result == null) return;

    if (result == 'scanner') {
      _analyzeFood();
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

              // 🚀 FIX: Leemos los pendientes desde el contexto
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
                await _guardarPlatoAnalizado(
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

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    final double caloriasMeta = (userData?['calorias_objetivo'] ?? 2000)
        .toDouble();

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

              CaloriesSummaryCard(
                consumidas: progressProvider.caloriasConsumidas,
                meta: caloriasMeta,
                macros: progressProvider.macrosConsumidos,
              ),
              const SizedBox(height: 20),

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
