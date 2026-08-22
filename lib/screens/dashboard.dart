// Archivo: lib/screens/dashboard.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/dashboard_service.dart';

import '../widgets/dashboard/profile_warning_card.dart';
import '../widgets/dashboard/dashboard_quick_actions.dart';

import '../widgets/ai_recommendation_card.dart';
import '../widgets/calories_summary_card.dart';
import '../widgets/free_intake_sheet.dart';
import '../widgets/meals_history_card.dart';

// Modales separados (Nivel 4)
import '../widgets/modals/add_menu_bottom_sheet.dart';
import '../widgets/modals/ai_feedback_dialog.dart';
import '../widgets/modals/ai_result_bottom_sheet.dart';
import '../widgets/modals/loading_ai_dialog.dart';
import '../widgets/modals/photo_confirmation_dialog.dart';

class Dashboard extends StatefulWidget {
  final Function(int)? onTabSelected;

  const Dashboard({super.key, this.onTabSelected});

  @override
  DashboardState createState() => DashboardState(); // ¡Guión bajo quitado!
}

class DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  // ¡Guión bajo quitado!
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? userData;
  bool _loading = true;
  int _intentosVision = 3;
  bool perfilIncompleto = false;

  // Variables de Progreso
  double caloriasConsumidas = 0.0;
  Map<String, dynamic> macrosConsumidos = {
    "carbohidratos_g": 0,
    "proteinas_g": 0,
    "grasas_g": 0,
  };
  List<String> historialConsumo = [];

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

    fetchInitialData(); // ¡Guión bajo quitado!
  }

  // 1. FASE LOCAL: Abrir cámara y pedir confirmación visual (¡GRATIS!)
  Future<void> _analyzeFood({bool esReintento = false}) async {
    if (!esReintento) {
      _intentosVision = 3;
    }

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

  // =========================================================================
  // 🧠 LÓGICA DE NEGOCIO (Delegada al Servicio)
  // =========================================================================

  Future<void> fetchInitialData() async {
    setState(() => _loading = true);
    try {
      // 1. El DashboardService hace todo el trabajo sucio
      final dataUsuario = await DashboardService.getUserData();
      final progreso = await DashboardService.getTodayProgress();

      if (mounted) {
        setState(() {
          userData = dataUsuario;
          perfilIncompleto = _checkPerfilIncompleto(dataUsuario);

          // 2. Cargamos el progreso si no dio error
          if (progreso != null) {
            caloriasConsumidas = (progreso['calorias_consumidas'] ?? 0).toDouble();
            macrosConsumidos = progreso['macros_consumidos'] ?? macrosConsumidos;
            if (progreso['historial'] != null) {
              historialConsumo = List<String>.from(progreso['historial']);
            }
          }
        });
      }
    } catch (e) {
      // 3. Manejo de errores limpio
      if (e.toString().contains('unauthorized')) {
        _showError("Sesión expirada. Inicia sesión de nuevo.");
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError("No se pudo conectar al servidor");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendPhotoToBackend(XFile image, bool esReintento) async {
    LoadingAiDialog.show(context);

    try {
      // El servicio maneja Multipart y parseos. ¡Solo 1 línea!
      final data = await DashboardService.analyzeVision(image);
      
      if (mounted) LoadingAiDialog.hide(context);
      if (mounted) {
        final action = await AiResultBottomSheet.show(
          context: context, data: data, intentosRestantes: _intentosVision - 1,
        );

        if (action == 'confirm') {
          await _guardarPlatoAnalizado(data);
        } else if (action == 'retry' && _intentosVision > 1) {
          _intentosVision--;
          _analyzeFood(esReintento: true);
        }
      }
    } catch (e) {
      if (mounted) LoadingAiDialog.hide(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Limpiamos la palabra "Exception:" que devuelve Dart por defecto
            content: Text('Ups: ${e.toString().replaceAll('Exception: ', '')}'), 
            backgroundColor: Colors.red.shade700
          ),
        );
      }
    }
  }

  Future<void> _guardarPlatoAnalizado(Map<String, dynamic> data) async {
    try {
      await DashboardService.saveIntake(data); // ¡Magia! Solo 1 línea.
      
      fetchInitialData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Comida guardada con éxito! 🚀'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la comida'), backgroundColor: Colors.red),
        );
      }
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

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nombre = userData?['nombre'] ?? "Usuario";
    final double caloriasMeta = (userData?['calorias_objetivo'] ?? 2000)
        .toDouble();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(nombre),
      floatingActionButton: _buildFloatingActionButton(),
      body: RefreshIndicator(
        onRefresh: fetchInitialData,
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
                consumidas: caloriasConsumidas,
                meta: caloriasMeta,
                macros: macrosConsumidos,
              ),
              const SizedBox(height: 20),

              if (historialConsumo.isNotEmpty) ...[
                MealsHistoryCard(historial: historialConsumo),
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

  // =========================================================================
  // 🧩 COMPONENTES EXTRAÍDOS (Clean Code)
  // =========================================================================

  AppBar _buildAppBar(String nombre) {
    return AppBar(
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
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _handleAddMenuAction, // Lógica delegada a un método
      backgroundColor: Colors.green.shade600,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.add, color: Colors.white, size: 32),
    );
  }

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
            onSuccess: (iaData) {
              AiFeedbackDialog.show(
                context,
                iaData,
              ).then((_) => fetchInitialData());
            },
          ),
        ),
      );
    }
  }
}
