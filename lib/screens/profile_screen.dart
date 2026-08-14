// Archivo: lib/screens/profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userData = {};
  bool _loading = true;
  bool _isUploadingPicture = false;

  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileFromCache();
  }

  void _updateAvatarUrlFromData(Map<String, dynamic> data) {
    if (data.containsKey('avatar_url') && data['avatar_url'] != null) {
      avatarUrl = data['avatar_url'];
    } else if (data.containsKey('foto_perfil') && data['foto_perfil'] != null) {
      // Por si acaso Google guarda en otra key
      avatarUrl = data['foto_perfil'];
    }
  }

  Future<void> _loadProfileFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('user_data');

    if (cachedData != null) {
      final decodedData = jsonDecode(cachedData);
      setState(() {
        _userData = decodedData;
        _updateAvatarUrlFromData(_userData);
        _loading = false;
      });
      // Aún teniendo caché, pedimos datos frescos de fondo para actualizar nivel/fotos
      _fetchProfileFresh();
    } else {
      _fetchProfileFresh();
    }
  }

  Future<void> _fetchProfileFresh() async {
    try {
      final response = await ApiClient.get("/db/me");
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', response.body);
        final freshData = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _userData = freshData;
            _updateAvatarUrlFromData(_userData);
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  // --- NUEVA FUNCIÓN PARA SUBIR LA FOTO ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUploadingPicture = true);

    try {
      final response = await ApiClient.postMultipart(
        '/db/users/me/avatar',
        image,
      );

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);

        setState(() {
          avatarUrl = data['avatar_url'];
        });

        _userData['avatar_url'] = data['avatar_url'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(_userData));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Foto actualizada!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al subir'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isUploadingPicture = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/login");
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: EditProfileSheet(
            userData: _userData,
            onSave: _updateLocalState,
          ),
        );
      },
    );
  }

  void _openNutritionalPreferencesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: MediaQuery.of(context).padding.top + 40,
          ),
          child: NutritionalPreferencesSheet(
            userData: _userData,
            onSave: _updateLocalState,
          ),
        );
      },
    );
  }

  Future<void> _updateLocalState(Map<String, dynamic> updatedData) async {
    setState(() {
      _userData = updatedData;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(updatedData));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final name = _userData["nombre"] ?? "Usuario";
    final goal = _userData["objetivo"] ?? "No definido";
    final weight = (_userData["peso"] ?? 0).toDouble();
    final progress = (weight / 100).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 1. Tarjeta de Identidad
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 8,
            shadowColor: Colors.green.withOpacity(0.2),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.green.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _isUploadingPicture ? null : _pickAndUploadImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green.shade300,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl!)
                                : null,
                            child: avatarUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.green.shade200,
                                  )
                                : null,
                          ),
                        ),
                        if (_isUploadingPicture)
                          Container(
                            width: 86,
                            height: 86,
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        if (!_isUploadingPicture)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            goal.toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Peso actual: ${weight.toStringAsFixed(1)} kg",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. Progreso
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            shadowColor: Colors.black12,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "Progreso hacia tu objetivo",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CircularPercentIndicator(
                    radius: 80.0,
                    lineWidth: 12.0,
                    percent: progress,
                    center: Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.black87,
                      ),
                    ),
                    progressColor: Colors.green.shade500,
                    backgroundColor: Colors.grey.shade200,
                    circularStrokeCap: CircularStrokeCap.round,
                    animation: true,
                    animationDuration: 1200,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 3. Menú de Configuración Elegante
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                "Configuración de tu Plan",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  title: const Text(
                    "Datos físicos y objetivo",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text("Edad, peso, altura, actividad..."),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _openEditSheet,
                ),
                const Divider(height: 1, indent: 70, endIndent: 20),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: Icon(
                      Icons.restaurant_menu,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  title: const Text(
                    "Gustos y Restricciones",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    "Alergias, dietas, alimentos favoritos...",
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _openNutritionalPreferencesSheet,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Accesos del sistema
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade50,
                child: Icon(Icons.logout, color: Colors.red.shade400),
              ),
              title: const Text(
                "Cerrar sesión",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: _logout,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ============================================================================
// 1. POPUP: EDITAR PERFIL FÍSICO (Datos Básicos)
// ============================================================================
class EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onSave;
  const EditProfileSheet({
    super.key,
    required this.userData,
    required this.onSave,
  });

  @override
  _EditProfileSheetState createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
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
    setState(() => _isSaving = true);

    try {
      final updatedData = {
        ...widget.userData, // Mantenemos preferencias y restricciones intactas
        "nombre": _nameCtrl.text.trim(),
        "edad": int.parse(_ageCtrl.text),
        "peso": double.parse(_weightCtrl.text),
        "altura": double.parse(_heightCtrl.text),
        "genero": _gender,
        "nivel_actividad": _activity,
        "objetivo": _goal,
      };

      final email = widget.userData['email'];
      final response = await ApiClient.put(
        "/db/users/$email",
        body: updatedData,
      );

      if (response.statusCode == 200) {
        widget.onSave(updatedData);
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception("Error del servidor");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar los datos")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
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
              "Datos Físicos",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // ... Mismos campos que la versión anterior para ahorrar espacio aquí
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: "Nombre",
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) => v!.isEmpty ? "Obligatorio" : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Edad",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: InputDecoration(
                      labelText: "Género",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "hombre", child: Text("Hombre")),
                      DropdownMenuItem(value: "mujer", child: Text("Mujer")),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Peso (kg)",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Altura (cm)",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _activity,
              decoration: InputDecoration(
                labelText: "Nivel Actividad",
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: "sedentario",
                  child: Text("Sedentario"),
                ),
                DropdownMenuItem(value: "ligero", child: Text("Ligero")),
                DropdownMenuItem(value: "moderado", child: Text("Moderado")),
                DropdownMenuItem(value: "activo", child: Text("Activo")),
                DropdownMenuItem(
                  value: "muy_activo",
                  child: Text("Muy Activo"),
                ),
              ],
              onChanged: (v) => setState(() => _activity = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _goal,
              decoration: InputDecoration(
                labelText: "Objetivo",
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(value: "perder", child: Text("Perder Grasa")),
                DropdownMenuItem(value: "mantener", child: Text("Mantener")),
                DropdownMenuItem(value: "ganar", child: Text("Ganar Músculo")),
              ],
              onChanged: (v) => setState(() => _goal = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveData,
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
                      "Guardar Cambios",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. POPUP: PREFERENCIAS NUTRICIONALES Y RESTRICCIONES (Chips)
// ============================================================================
class NutritionalPreferencesSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onSave;
  const NutritionalPreferencesSheet({
    super.key,
    required this.userData,
    required this.onSave,
  });

  @override
  _NutritionalPreferencesSheetState createState() =>
      _NutritionalPreferencesSheetState();
}

class _NutritionalPreferencesSheetState
    extends State<NutritionalPreferencesSheet> {
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

      final email = widget.userData['email'];
      final response = await ApiClient.put(
        "/db/users/$email",
        body: updatedData,
      );

      if (response.statusCode == 200) {
        widget.onSave(updatedData);
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception("Error del servidor");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar preferencias")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _isSaving ? null : _saveData,
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
