import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "";
  String goal = "";
  double weight = 0;
  double progress = 0.0;
  String avatarUrl =
      "https://images.ctfassets.net/h6goo9gw1hh6/2sNZtFAWOdP1lmQ33VwRN3/e40b6ea6361a1abe28f32e7910f63b66/1-intro-photo-final.jpg?w=1200&h=992&fl=progressive&q=70&fm=jpg";

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token");

      if (token == null) return;

      final url = Uri.parse("http://127.0.0.1:8000/db/me");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          name = data["nombre"] ?? "";
          goal = data["objetivo"] ?? "";
          weight = (data["peso"] ?? 0).toDouble();
          // Ejemplo de cálculo de progreso:
          progress = (weight / 100).clamp(0, 1); // Ajusta según tu lógica real
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<bool> _updateProfile(
    String newName,
    String newGoal,
    double newWeight,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token");

      if (token == null) return false;

      final url = Uri.parse("http://127.0.0.1:8000/db/me");
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nombre": newName,
          "objetivo": newGoal,
          "peso": newWeight,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar y datos principales
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text("Objetivo: $goal"),
                        const SizedBox(height: 6),
                        Text("Peso actual: ${weight.toStringAsFixed(1)} kg"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Progreso hacia objetivo
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Progreso hacia tu objetivo",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  CircularPercentIndicator(
                    radius: 80.0,
                    lineWidth: 12.0,
                    percent: progress,
                    center: Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    progressColor: Colors.green,
                    backgroundColor: Colors.grey[300]!,
                    animation: true,
                    animateFromLastPercent: true,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Botón editar datos
          ElevatedButton.icon(
            onPressed: () {
              _editProfileDialog();
            },
            icon: const Icon(Icons.edit),
            label: const Text("Editar perfil"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[400],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Accesos rápidos
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text("Notificaciones"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Cerrar sesión"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token");

      if (token != null) {
        final url = Uri.parse("http://127.0.0.1:8000/db/logout");
        final response = await http.post(
          url,
          headers: {"Authorization": "Bearer $token"},
        );

        if (response.statusCode == 200) {
          // Borrar token local
          await prefs.remove("access_token");

          if (!mounted) return;
          Navigator.pushReplacementNamed(context, "/login");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al cerrar sesión (${response.statusCode})"),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No se pudo cerrar sesión")));
    }
  }

  void _editProfileDialog() {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController goalController = TextEditingController(text: goal);
    TextEditingController weightController = TextEditingController(
      text: weight.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar perfil"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nombre"),
                ),
                TextField(
                  controller: goalController,
                  decoration: const InputDecoration(labelText: "Objetivo"),
                ),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Peso actual (kg)",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedName = nameController.text;
                final updatedGoal = goalController.text;
                final updatedWeight =
                    double.tryParse(weightController.text) ?? weight;

                final success = await _updateProfile(
                  updatedName,
                  updatedGoal,
                  updatedWeight,
                );

                if (success && mounted) {
                  setState(() {
                    name = updatedName;
                    goal = updatedGoal;
                    weight = updatedWeight;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }
}
