// Archivo: lib/widgets/modals/profile/nutritional_preferences_sheet.dart
import 'package:flutter/material.dart';
// 🌟 FIX: Solo 3 saltos hacia atrás
import '../../../services/dashboard_service.dart';

class NutritionalPreferencesSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onSave;

  const NutritionalPreferencesSheet({
    super.key,
    required this.userData,
    required this.onSave,
  });

  @override
  State<NutritionalPreferencesSheet> createState() =>
      _NutritionalPreferencesSheetState();
}

class _NutritionalPreferencesSheetState
    extends State<NutritionalPreferencesSheet> {
  // 🌟 FIX: Restauramos las variables de estado
  final List<String> _availableRestrictions = [
    "Gluten",
    "Lactosa",
    "Mariscos",
    "Frutos secos",
    "Vegano",
    "Vegetariano",
    "Huevo",
  ];

  List<String> _selectedRestrictions = [];
  List<String> _preferences = [];
  final TextEditingController _prefController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.userData;

    // Inicializar listas desde backend
    if (u['restricciones'] != null) {
      _selectedRestrictions = List<String>.from(
        u['restricciones'],
      ).map((e) => e.toString().toLowerCase().trim()).toList();
    }
    if (u['preferencias'] != null) {
      _preferences = List<String>.from(
        u['preferencias'],
      ).map((e) => e.toString().trim()).toList();
    }
  }

  @override
  void dispose() {
    _prefController.dispose();
    super.dispose();
  }

  void _addPreference() {
    final text = _prefController.text.trim();
    if (text.isNotEmpty &&
        !_preferences.any((p) => p.toLowerCase() == text.toLowerCase())) {
      setState(() => _preferences.add(text));
      _prefController.clear();
    }
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    try {
      final updatedData = {
        ...widget.userData, // Mantenemos datos físicos intactos
        "restricciones": _selectedRestrictions,
        "preferencias": _preferences,
      };

      // 🌟 Usamos la arquitectura central (DashboardService)
      await DashboardService.updateUserData(updatedData);

      widget.onSave(updatedData); // Avisamos a ProfileScreen
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al guardar preferencias"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 FIX: Restauramos toda la UI de los Chips y botones
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Gustos y Restricciones",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "La IA usará esta información para crear tu menú.",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // RESTRICCIONES
          const Text(
            "Alergias y Dietas",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableRestrictions.map((res) {
              final isSelected = _selectedRestrictions.contains(
                res.toLowerCase(),
              );
              return FilterChip(
                label: Text(res),
                selected: isSelected,
                selectedColor: Colors.orange.shade100,
                checkmarkColor: Colors.orange.shade800,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.orange.shade900 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedRestrictions.add(res.toLowerCase());
                    } else {
                      _selectedRestrictions.remove(res.toLowerCase());
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // PREFERENCIAS (Agregar alimentos)
          const Text(
            "Alimentos Favoritos",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _prefController,
                  decoration: InputDecoration(
                    hintText: "Ej. Pollo, Salmón, Avena...",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _addPreference(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.add, color: Colors.green.shade800),
                  onPressed: _addPreference,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // CHIPS DE PREFERENCIAS AÑADIDAS
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _preferences.map((pref) {
              return InputChip(
                label: Text(
                  pref,
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Colors.green.shade50,
                deleteIconColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.green.shade200),
                ),
                onDeleted: () {
                  setState(() => _preferences.remove(pref));
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSaving ? null : _saveData, // 🌟 Conectado!
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "Guardar Preferencias",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
