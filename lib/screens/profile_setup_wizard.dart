import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileSetupWizard extends StatefulWidget {
  const ProfileSetupWizard({Key? key}) : super(key: key);

  @override
  _ProfileSetupWizardState createState() => _ProfileSetupWizardState();
}

class _ProfileSetupWizardState extends State<ProfileSetupWizard> {
  int _currentStep = 0;
  Map<String, dynamic> profileData = {
    "edad": null,
    "peso": null,
    "altura": null,
    "genero": null,
    "nivel_actividad": null,
    "objetivo": null,
    "preferencias": [],
    "restricciones": []
  };

  final _edadController = TextEditingController();
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();

  Future<void> _submitProfile(String email) async {
    // convertir controllers a números
    profileData["edad"] = int.tryParse(_edadController.text);
    profileData["peso"] = double.tryParse(_pesoController.text);
    profileData["altura"] = double.tryParse(_alturaController.text);

    final url = Uri.parse("http://127.0.0.1:8000/db/users/$email");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 200 && mounted) {
      Navigator.pushReplacementNamed(context, "/main");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error guardando perfil")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: const Text("Configura tu perfil")),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            setState(() => _currentStep += 1);
          } else {
            _submitProfile(email);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep -= 1);
        },
        steps: [
          Step(
            title: const Text("Datos básicos"),
            content: Column(
              children: [
                TextField(
                  controller: _edadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Edad"),
                ),
                TextField(
                  controller: _pesoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Peso (kg)"),
                ),
                TextField(
                  controller: _alturaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Altura (cm)"),
                ),
              ],
            ),
          ),
          Step(
            title: const Text("Género"),
            content: Wrap(
              spacing: 10,
              children: [
                {"label": "Hombre", "value": "hombre"},
                {"label": "Mujer", "value": "mujer"},
                {"label": "Otro", "value": "otro"},
              ].map((item) {
                return ChoiceChip(
                  label: Text(item["label"]!),
                  selected: profileData["genero"] == item["value"],
                  onSelected: (_) =>
                      setState(() => profileData["genero"] = item["value"]),
                );
              }).toList(),
            ),
          ),
          Step(
            title: const Text("Nivel de actividad"),
            content: Wrap(
              spacing: 10,
              children: [
                {"label": "Sedentario", "value": "sedentario"},
                {"label": "Ligero", "value": "ligero"},
                {"label": "Moderado", "value": "moderado"},
                {"label": "Activo", "value": "activo"},
                {"label": "Muy activo", "value": "muy_activo"},
              ].map((item) {
                return ChoiceChip(
                  label: Text(item["label"]!),
                  selected: profileData["nivel_actividad"] == item["value"],
                  onSelected: (_) =>
                      setState(() => profileData["nivel_actividad"] = item["value"]),
                );
              }).toList(),
            ),
          ),
          Step(
            title: const Text("Objetivo"),
            content: Wrap(
              spacing: 10,
              children: [
                {"label": "Perder peso", "value": "perder"},
                {"label": "Mantener peso", "value": "mantener"},
                {"label": "Ganar músculo", "value": "ganar"},
              ].map((item) {
                return ChoiceChip(
                  label: Text(item["label"]!),
                  selected: profileData["objetivo"] == item["value"],
                  onSelected: (_) =>
                      setState(() => profileData["objetivo"] = item["value"]),
                );
              }).toList(),
            ),
          ),
          Step(
            title: const Text("Preferencias y restricciones"),
            content: Column(
              children: [
                const Text("Preferencias"),
                Wrap(
                  spacing: 10,
                  children: ["pollo", "arroz", "pescado", "verduras"].map((p) {
                    return FilterChip(
                      label: Text(p),
                      selected: profileData["preferencias"].contains(p),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            profileData["preferencias"].add(p);
                          } else {
                            profileData["preferencias"].remove(p);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                const Text("Restricciones"),
                Wrap(
                  spacing: 10,
                  children: ["sin gluten", "sin lactosa", "vegetariano"].map((r) {
                    return FilterChip(
                      label: Text(r),
                      selected: profileData["restricciones"].contains(r),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            profileData["restricciones"].add(r);
                          } else {
                            profileData["restricciones"].remove(r);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}