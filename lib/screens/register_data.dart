import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class RegisterDataScreen extends StatefulWidget {
  const RegisterDataScreen({super.key});

  @override
  State<RegisterDataScreen> createState() => _RegisterDataScreenState();
}

class _RegisterDataScreenState extends State<RegisterDataScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = false; // <-- Añade esta línea

  int? edad;
  double? peso;
  double? altura;
  String? genero;
  String? nivelActividad;
  String? objetivo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Crea tu perfil",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Cuéntanos sobre ti 📝",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Usaremos estos datos para personalizar tu plan de nutrición.",
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Edad
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Edad",
                    prefixIcon: const Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => edad = int.tryParse(value ?? ""),
                  validator: (value) =>
                      value!.isEmpty ? "Introduce tu edad" : null,
                ),
                const SizedBox(height: 20),

                // Peso
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Peso (kg)",
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => peso = double.tryParse(value ?? ""),
                  validator: (value) =>
                      value!.isEmpty ? "Introduce tu peso" : null,
                ),
                const SizedBox(height: 20),

                // Altura
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Altura (cm)",
                    prefixIcon: const Icon(Icons.height),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => altura = double.tryParse(value ?? ""),
                  validator: (value) =>
                      value!.isEmpty ? "Introduce tu altura" : null,
                ),
                const SizedBox(height: 20),

                // Género
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Género",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: ["Hombre", "Mujer"].map((g) {
                    return DropdownMenuItem(value: g, child: Text(g));
                  }).toList(),
                  onChanged: (val) => genero = val,
                  validator: (value) =>
                      value == null ? "Selecciona tu género" : null,
                ),
                const SizedBox(height: 20),

                // Nivel de actividad
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Nivel de actividad",
                    prefixIcon: const Icon(Icons.directions_run_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: [
                    "Sedentario",
                    "Ligero",
                    "Moderado",
                    "Activo",
                    "Muy activo"
                  ].map((nivel) {
                    return DropdownMenuItem(value: nivel, child: Text(nivel));
                  }).toList(),
                  onChanged: (val) => nivelActividad = val,
                  validator: (value) =>
                      value == null ? "Selecciona tu actividad" : null,
                ),
                const SizedBox(height: 20),

                // Objetivo
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Objetivo",
                    prefixIcon: const Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: [
                    "Perder peso",
                    "Mantener",
                    "Ganar músculo"
                  ].map((obj) {
                    return DropdownMenuItem(value: obj, child: Text(obj));
                  }).toList(),
                  onChanged: (val) => objetivo = val,
                  validator: (value) =>
                      value == null ? "Selecciona tu objetivo" : null,
                ),

                const SizedBox(height: 40),

                // Botón
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          // 1. Validamos que el usuario haya rellenado todos los campos del formulario
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();

                            setState(() {
                              _loading = true;
                            });

                            try {
                              // 2. Recuperamos el email que guardamos en el login/registro
                              final prefs = await SharedPreferences.getInstance();
                              final email = prefs.getString('user_email');

                              if (email == null || email.isEmpty) {
                                throw Exception("No se encontró el email del usuario");
                              }

                              // 3. Formateamos los datos como los espera tu backend en Python
                              final body = {
                                "edad": edad,
                                "peso": peso,
                                "altura": altura,
                                "genero": genero?.toLowerCase(), // "hombre" / "mujer"
                                "nivel_actividad": nivelActividad?.toLowerCase(), // "sedentario", "activo", etc.
                                "objetivo": objetivo?.toLowerCase().split(' ')[0], // Toma la primera palabra: "perder", "mantener", "ganar"
                                "preferencias": [],
                                "restricciones": []
                              };

                              // 4. Enviamos la petición PUT a /db/users/email@ejemplo.com
                              final response = await ApiClient.put('/db/users/$email', body: body);

                              if (response.statusCode == 200 || response.statusCode == 201) {
                                if (!mounted) return;
                                // Redirigimos a la pantalla principal
                                Navigator.pushReplacementNamed(context, '/main');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error del servidor: ${response.statusCode}")),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error al guardar datos: $e")),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _loading = false;
                                });
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Continuar",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}