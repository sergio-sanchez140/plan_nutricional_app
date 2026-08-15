// Archivo: lib/screens/dashboard.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../widgets/free_intake_sheet.dart';
import 'package:plan_nutricional_app/widgets/macro_chip.dart';
import 'package:plan_nutricional_app/widgets/quick_action_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../widgets/macro_row.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/calories_summary_card.dart';
import '../widgets/meals_history_card.dart';
import '../widgets/ai_recommendation_card.dart';
import '../utils/dashboard_modals.dart';

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

  // 1. FUNCIÓN PRINCIPAL QUE DISPARA LA CÁMARA Y LA IA
  Future<void> _analyzeFood() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    // AHORA LLAMAMOS AL ARCHIVO EXTERNO
    DashboardModals.showLoadingDialog(context);

    try {
      final response = await ApiClient.postMultipart(
        '/ai/vision/analyze',
        image,
      );
      if (mounted) Navigator.pop(context); // Cierra loader

      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());

        if (mounted) {
          // AHORA LLAMAMOS AL ARCHIVO EXTERNO
          DashboardModals.showResultModal(
            context: context,
            data: data,
            onConfirm: () {
              // Aquí llamaremos a la API para registrar el plato
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Guardado!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      // ... manejo de error ...
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error al analizar el plato. ¿Es comida de verdad? 🤔',
            ),
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
          // 1. Esperamos a que el usuario elija y el menú se cierre del todo
          final result = await DashboardModals.showAddMenu(context);

          // 🛡️ ESCUDO 1: Si cerramos el modal tocando fuera (result == null)
          // o si la pantalla ya no existe (!mounted), abortamos para no crashear.
          if (!mounted || result == null) return;

          if (result == 'scanner') {
            _analyzeFood();
          } else if (result == 'manual') {
            showModalBottomSheet(
              context: context,
              isScrollControlled:
                  true, // Esto es vital para que pueda subir con el teclado
              backgroundColor: Colors.transparent,
              builder: (context) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: FreeIntakeSheet(
                  onSuccess: (iaData) {
                    // 👇 ¡Magia restaurada! Usamos el popup de feedback
                    DashboardModals.showAIFeedbackDialog(
                      context: context,
                      iaData: iaData,
                      onOk: () {
                        // Cuando el usuario le da a "Genial", refrescamos la gráfica
                        fetchInitialData();
                      },
                    );
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
