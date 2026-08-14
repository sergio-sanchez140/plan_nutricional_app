// Archivo: lib/screens/dashboard.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

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
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircularPercentIndicator(
                            radius: 65.0,
                            lineWidth: 12.0,
                            percent: progresoCalorias,
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  caloriasConsumidas.toInt().toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  "/ ${caloriasMeta.toInt()} kcal",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            progressColor: Colors.green,
                            backgroundColor: Colors.grey.shade200,
                            animation: true,
                            animateFromLastPercent: true,
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Progreso de Hoy",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _MacroRow(
                                  label: "Carbos",
                                  value:
                                      "${macrosConsumidos['carbohidratos_g']}g",
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 4),
                                _MacroRow(
                                  label: "Proteínas",
                                  value: "${macrosConsumidos['proteinas_g']}g",
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 4),
                                _MacroRow(
                                  label: "Grasas",
                                  value: "${macrosConsumidos['grasas_g']}g",
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- 2. HISTORIAL DE COMIDAS (Nuevo) ---
              if (historialConsumo.isNotEmpty) ...[
                const Text(
                  "Comidas de hoy",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(), // Evita conflicto con el scroll general
                    itemCount: historialConsumo.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 60, endIndent: 20),
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          historialConsumo[index],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // --- 3. RECOMENDACIÓN IA ---
              SlideTransition(
                position: _slideAnimation,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.green[50],
                  elevation: 4,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.green),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Mantén un buen ritmo. Trata de cenar al menos 2 horas antes de ir a dormir 🌙",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                "Acciones rápidas",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _quickActionButton(Icons.restaurant_menu, "Plan", 1),
                  _quickActionButton(Icons.emoji_events, "Retos", 2),
                  _quickActionButton(Icons.person, "Perfil", 3),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionButton(IconData icon, String label, int tabIndex) {
    return GestureDetector(
      onTap: () {
        if (widget.onTabSelected != null) {
          widget.onTabSelected!(tabIndex);
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.green[100],
            child: Icon(icon, color: Colors.green[700]),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
