// Archivo: lib/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:plan_nutricional_app/providers/progress_provider.dart';
import 'package:provider/provider.dart';
import '../services/dashboard_service.dart'; // 🌟 Importación ajustada

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _nameCtrl, _ageCtrl, _weightCtrl, _heightCtrl;
  String? _gender, _activity, _goal;

  @override
  void initState() {
    super.initState();
    final u = widget.userData;
    _nameCtrl = TextEditingController(text: u['nombre']?.toString() ?? '');
    _ageCtrl = TextEditingController(text: u['edad']?.toString() ?? '');
    _weightCtrl = TextEditingController(text: u['peso']?.toString() ?? '');
    _heightCtrl = TextEditingController(text: u['altura']?.toString() ?? '');

    _gender = _safeDropdownValue(u['genero'], ["hombre", "mujer"]);
    _activity = _safeDropdownValue(u['nivel_actividad'], [
      "sedentario",
      "ligero",
      "moderado",
      "activo",
      "muy_activo",
    ]);
    _goal = _safeDropdownValue(u['objetivo'], ["perder", "mantener", "ganar"]);
  }

  String? _safeDropdownValue(dynamic val, List<String> validOptions) {
    if (val == null) return null;
    final str = val.toString().toLowerCase();
    return validOptions.contains(str) ? str : null;
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Recogemos los valores actuales del formulario
    final newName = _nameCtrl.text.trim();
    final newAge = int.tryParse(_ageCtrl.text) ?? 25;
    final newWeight =
        double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 70.0;
    final newHeight =
        double.tryParse(_heightCtrl.text.replaceAll(',', '.')) ?? 170.0;

    // 🌟 2. DIRTY CHECKING: ¿Ha cambiado algo realmente?
    final u = widget.userData;
    final hasChanges =
        newName != (u['nombre']?.toString() ?? '') ||
        newAge != (u['edad'] ?? 0) ||
        newWeight != (u['peso'] ?? 0.0) ||
        newHeight != (u['altura'] ?? 0.0) ||
        _gender != u['genero'] ||
        _activity != u['nivel_actividad'] ||
        _goal != u['objetivo'];

    // Si no hay cambios, cerramos la pantalla en silencio y nos ahorramos la llamada
    if (!hasChanges) {
      Navigator.pop(context);
      return;
    }

    // 3. Si hay cambios, procedemos a guardar
    setState(() => _isSaving = true);

    try {
      final updatedData = {
        ...widget.userData,
        "nombre": newName,
        "edad": newAge,
        "peso": newWeight,
        "altura": newHeight,
        "genero": _gender,
        "nivel_actividad": _activity,
        "objetivo": _goal,
      };

      // Guardamos en base de datos
      await DashboardService.updateUserData(updatedData);

      if (mounted) {
        // 🌟 2. EL FIX: Avisamos al Dashboard de que recargue los datos silenciosamente
        context.read<ProgressProvider>().setProfileNeedsRefresh(true);

        Navigator.pop(context, updatedData);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al guardar los datos"),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Datos y Objetivo",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveData,
                  child: const Text(
                    "Guardar",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("DATOS PERSONALES"),
              _buildFormCard([
                _buildTextField("Nombre", _nameCtrl, isRequired: true),
                _buildDivider(),
                _buildDropdown("Género", _gender, [
                  const DropdownMenuItem(
                    value: "hombre",
                    child: Text("Hombre"),
                  ),
                  const DropdownMenuItem(value: "mujer", child: Text("Mujer")),
                ], (v) => setState(() => _gender = v)),
                _buildDivider(),
                _buildTextField("Edad", _ageCtrl, isNumber: true),
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle("MÉTRICAS FÍSICAS"),
              _buildFormCard([
                _buildTextField("Peso (kg)", _weightCtrl, isDecimal: true),
                _buildDivider(),
                _buildTextField("Altura (cm)", _heightCtrl, isDecimal: true),
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle("PLAN NUTRICIONAL"),
              _buildFormCard([
                _buildDropdown(
                  "Nivel de Actividad",
                  _activity,
                  [
                    const DropdownMenuItem(
                      value: "sedentario",
                      child: Text("Sedentario"),
                    ),
                    const DropdownMenuItem(
                      value: "ligero",
                      child: Text("Ligero"),
                    ),
                    const DropdownMenuItem(
                      value: "moderado",
                      child: Text("Moderado"),
                    ),
                    const DropdownMenuItem(
                      value: "activo",
                      child: Text("Activo"),
                    ),
                    const DropdownMenuItem(
                      value: "muy_activo",
                      child: Text("Muy Activo"),
                    ),
                  ],
                  (v) => setState(() => _activity = v),
                ),
                _buildDivider(),
                _buildDropdown("Objetivo", _goal, [
                  const DropdownMenuItem(
                    value: "perder",
                    child: Text("Perder Grasa"),
                  ),
                  const DropdownMenuItem(
                    value: "mantener",
                    child: Text("Mantener Peso"),
                  ),
                  const DropdownMenuItem(
                    value: "ganar",
                    child: Text("Ganar Músculo"),
                  ),
                ], (v) => setState(() => _goal = v)),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 WIDGETS AUXILIARES PARA UN DISEÑO LIMPIO (Estilo iOS)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() => const Divider(
    height: 1,
    indent: 16,
    endIndent: 0,
    color: Color(0xFFEEEEEE),
  );

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    bool isDecimal = false,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: isDecimal
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : (isNumber ? TextInputType.number : TextInputType.text),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "...",
                hintStyle: TextStyle(color: Colors.grey),
              ),
              validator: isRequired
                  ? (v) => v!.isEmpty ? "Obligatorio" : null
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                alignment: Alignment.centerRight,
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
