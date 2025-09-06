import 'package:flutter/material.dart';

class RegisterDataScreen extends StatefulWidget {
  const RegisterDataScreen({super.key});

  @override
  State<RegisterDataScreen> createState() => _RegisterDataScreenState();
}

class _RegisterDataScreenState extends State<RegisterDataScreen> {
  final _formKey = GlobalKey<FormState>();

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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      // TODO: Guardar en API
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
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