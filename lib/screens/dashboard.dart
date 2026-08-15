// Archivo: lib/screens/dashboard.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../widgets/ai_recommendation_card.dart';
import '../widgets/calories_summary_card.dart';
import '../widgets/free_intake_sheet.dart';
import '../widgets/meals_history_card.dart';
import '../widgets/quick_action_button.dart';

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

  // 2. FASE SERVIDOR: Envío de foto a la IA
  Future<void> _sendPhotoToBackend(XFile image, bool esReintento) async {
    LoadingAiDialog.show(context);

    try {
      final response = await ApiClient.postMultipart(
        '/ai/vision/analyze',
        image,
      );
      if (mounted) LoadingAiDialog.hide(context);

      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseString);

        if (mounted) {
          final String? action = await AiResultBottomSheet.show(
            context: context,
            data: data,
            intentosRestantes: _intentosVision - 1,
          );

          if (action == 'confirm') {
            await _guardarPlatoAnalizado(data);
          } else if (action == 'retry' && _intentosVision > 1) {
            _intentosVision--;
            _analyzeFood(esReintento: true);
          }
        }
      } else {
        String mensajeError = "Error desconocido al analizar la imagen.";
        try {
          final errorData = jsonDecode(responseString);
          if (errorData['detail'] != null) {
            mensajeError = errorData['detail'];
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ups: $mensajeError'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) LoadingAiDialog.hide(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // FUNCIÓN PARA MANDAR EL JSON AL BACKEND
  Future<void> _guardarPlatoAnalizado(Map<String, dynamic> data) async {
    try {
      // ⚠️ IMPORTANTE: Aquí debes poner la ruta de tu backend que guarda comidas confirmadas.
      // He puesto '/db/intakes' como ejemplo. Ajusta la URL según tu API.
      final response = await ApiClient.post(
        '/db/intakes', // O '/ai/intakes/vision/save', etc.
        body: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Si se guardó con éxito, recargamos la pantalla para actualizar la barrita de progreso
        fetchInitialData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Comida guardada con éxito! 🚀'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("Error del servidor");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo guardar la comida: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- AQUÍ QUITAMOS EL GUIÓN BAJO PARA HACERLA PÚBLICA ---
  Future<void> fetchInitialData() async {
    setState(() => _loading = true);
    await _fetchUserData();
    await _fetchTodayProgress();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchTodayProgress() async {
    try {
      final response = await ApiClient.get('/ai/intakes/today');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            caloriasConsumidas = (data['calorias_consumidas'] ?? 0).toDouble();
            macrosConsumidos = data['macros_consumidos'] ?? macrosConsumidos;

            // Leemos el array de historial (con safe cast para evitar errores)
            if (data['historial'] != null) {
              historialConsumo = List<String>.from(data['historial']);
            }
          });
        }
      }
    } catch (e) {
      // Ignoramos errores de red temporalmente
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cachedData = prefs.getString('user_data');
      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        setState(() {
          userData = data;
          perfilIncompleto = _checkPerfilIncompleto(data);
        });
      }

      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await ApiClient.get('/db/me');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await prefs.setString('user_data', response.body);
        await prefs.setString('user_email', data['email'] ?? '');

        if (mounted) {
          setState(() {
            userData = data;
            perfilIncompleto = _checkPerfilIncompleto(data);
          });
        }
      } else if (response.statusCode == 401) {
        _showError("Sesión expirada. Inicia sesión de nuevo.");
        await prefs.clear();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (userData == null) {
        _showError("No se pudo conectar al servidor");
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
    final double progresoCalorias = (caloriasConsumidas / caloriasMeta).clamp(
      0.0,
      1.0,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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
                    AiFeedbackDialog.show(context, iaData).then((_) {
                      fetchInitialData();
                    });
                  },
                ),
              ),
            );
          }
        },
        backgroundColor: Colors.green.shade600,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
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
                Card(
                  color: Colors.orange[50],
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: const Text("Tu perfil está incompleto"),
                    subtitle: const Text(
                      "Completa tus datos para personalizar tu plan",
                    ),
                    trailing: ElevatedButton(
                      child: const Text("Completar"),
                      onPressed: () {
                        if (widget.onTabSelected != null)
                          widget.onTabSelected!(3);
                      },
                    ),
                  ),
                ),

              // --- 1. RESUMEN DE CALORÍAS ---
              CaloriesSummaryCard(
                consumidas: caloriasConsumidas,
                meta: caloriasMeta,
                macros: macrosConsumidos,
              ),
              const SizedBox(height: 20),

              // --- 2. HISTORIAL DE COMIDAS ---
              if (historialConsumo.isNotEmpty)
                MealsHistoryCard(historial: historialConsumo),
              const SizedBox(height: 20),

              // --- 3. RECOMENDACIÓN IA ---
              AIRecommendationCard(animation: _slideAnimation),
              const SizedBox(height: 24),

              const Text(
                "Acciones rápidas",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  QuickActionButton(
                    icon: Icons.restaurant_menu,
                    label: "Plan",
                    tabIndex: 1,
                    onTabSelected:
                        widget.onTabSelected, // Pasamos el cable aquí
                  ),
                  QuickActionButton(
                    icon: Icons.emoji_events,
                    label: "Retos",
                    tabIndex: 2,
                    onTabSelected: widget.onTabSelected, // Y aquí
                  ),
                  QuickActionButton(
                    icon: Icons.person,
                    label: "Perfil",
                    tabIndex: 3,
                    onTabSelected: widget.onTabSelected, // Y aquí
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
