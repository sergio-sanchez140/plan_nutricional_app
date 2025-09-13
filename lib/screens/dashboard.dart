import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  final Function(int)? onTabSelected;

  const Dashboard({Key? key, this.onTabSelected}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
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
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        _showError("Sesión expirada. Inicia sesión de nuevo.");
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final url = Uri.parse('http://127.0.0.1:8000/db/me');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userData = data;
          perfilIncompleto = _checkPerfilIncompleto(data);
          _loading = false;
        });
      } else if (response.statusCode == 401) {
        _showError("Sesión no válida. Vuelve a iniciar sesión.");
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        _showError("Error ${response.statusCode} al cargar datos");
        setState(() => _loading = false);
      }
    } catch (e) {
      _showError("No se pudo conectar al servidor");
      setState(() => _loading = false);
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final nombre = userData?['nombre'] ?? "Usuario";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "¡Hola, $nombre! 🌟",
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  subtitle: const Text("Completa tus datos para personalizar tu plan"),
                  trailing: ElevatedButton(
                    child: const Text("Completar"),
                    onPressed: () {
                      final email = userData?["email"];
                      Navigator.pushNamed(context, '/profileSetup', arguments: email);
                    },
                  ),
                ),
              ),
            // --- Resumen de calorías y macros ---
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircularPercentIndicator(
                      radius: 70.0,
                      lineWidth: 12.0,
                      percent: 0.65,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text("1300",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20)),
                          Text("kcal")
                        ],
                      ),
                      progressColor: Colors.green,
                      backgroundColor: Colors.grey,
                      animation: true,
                      animateFromLastPercent: true,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Resumen Diario",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 10),
                          Text("Edad: ${userData?['edad'] ?? '-'}"),
                          Text("Peso: ${userData?['peso'] ?? '-'} kg"),
                          Text("Altura: ${userData?['altura'] ?? '-'} cm"),
                          Text("Objetivo: ${userData?['objetivo'] ?? '-'}"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // --- Recomendación IA diaria ---
            SlideTransition(
              position: _slideAnimation,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                          "Hoy aumenta tu ingesta de proteína 🥩 para optimizar tu energía",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // --- Acciones rápidas ---
            const Text("Acciones rápidas",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _quickActionButton(Icons.restaurant_menu, "Plan de comidas", 1),
                _quickActionButton(Icons.emoji_events, "Retos", 2),
                _quickActionButton(Icons.person, "Perfil", 3),
              ],
            ),
            const SizedBox(height: 20),
            // --- Retos / Gamificación ---
            const Text("Retos del día",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _challengeCard("Completa tu meta de proteína +5g", 0.6),
            _challengeCard("Bebe 2L de agua 💧", 0.8),
          ],
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
          Text(label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _challengeCard(String title, double progress) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey,
              color: Colors.green,
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }
}
