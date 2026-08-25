// Archivo: lib/screens/profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/dashboard_service.dart';
import '../providers/progress_provider.dart';
import 'edit_profile_screen.dart'; // 🌟 Importamos la nueva pantalla
import '../widgets/modals/profile/nutritional_preferences_sheet.dart';
// 🌟 Importamos los componentes visuales extraídos
import '../widgets/profile/profile_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
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
      avatarUrl = data['foto_perfil'];
    }
  }

  Future<void> _loadProfileFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('user_data');

    if (cachedData != null) {
      setState(() {
        _userData = jsonDecode(cachedData);
        _updateAvatarUrlFromData(_userData);
        _loading = false;
      });
      _fetchProfileFresh();
    } else {
      _fetchProfileFresh();
    }
  }

  Future<void> _fetchProfileFresh() async {
    try {
      final freshData = await DashboardService.getUserData();
      if (mounted) {
        setState(() {
          _userData = freshData;
          _updateAvatarUrlFromData(_userData);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

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
        final data = jsonDecode(await response.stream.bytesToString());

        setState(() => avatarUrl = data['avatar_url']);
        _userData['avatar_url'] = data['avatar_url'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(_userData));

        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Foto actualizada!'),
              backgroundColor: Colors.green,
            ),
          );
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

  // 🌟 EL SECRETO UX: RECALCULAR TRAS GUARDAR (VERSIÓN LIMPIA)
  Future<void> _updateLocalState(Map<String, dynamic> updatedData) async {
    // 1. Actualizamos la UI al instante (cero lag para el usuario)
    setState(() => _userData = updatedData);

    try {
      // 2. Forzamos al cerebro a bajar las nuevas calorías del día en segundo plano (silencioso)
      await context.read<ProgressProvider>().fetchProgress(silent: true);
      context.read<ProgressProvider>().setPlanNeedsRefresh(true);

      // 3. Feedback único, elegante y no intrusivo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Perfil actualizado correctamente",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error recalculando progreso: $e");
    }
  }

  // 🌟 NAVEGACIÓN DE PANTALLA COMPLETA
  Future<void> _openEditScreen() async {
    // Navegamos y esperamos a que la pantalla devuelva los datos al cerrarse
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: _userData),
      ),
    );

    // Si devolvió datos (no canceló), actualizamos la UI y recalculamos
    if (updatedData != null && updatedData is Map<String, dynamic>) {
      _updateLocalState(updatedData);
    }
  }

  void _openNutritionalPreferencesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: MediaQuery.of(context).padding.top + 40,
        ),
        child: NutritionalPreferencesSheet(
          userData: _userData,
          onSave: _updateLocalState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );

    final name = _userData["nombre"] ?? "Usuario";
    final goal = _userData["objetivo"] ?? "No definido";
    final weight = (_userData["peso"] ?? 0).toDouble();

    // 🌟 AHORA SÍ: Usamos los datos reales del backend
    final level = _userData["nivel"] ?? 1;
    final xp = _userData["xp"] ?? 0;
    final streak = _userData["racha_dias"] ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Mi Perfil",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProfileIdentityCard(
              name: name,
              goal: goal,
              weight: weight,
              avatarUrl: avatarUrl,
              isUploadingPicture: _isUploadingPicture,
              onPickImage: _pickAndUploadImage,
            ),
            const SizedBox(height: 24),

            // 🌟 AHORA SÍ: La tarjeta de stats reales
            ProfileGamificationCard(level: level, xp: xp, streak: streak),

            const SizedBox(height: 24),
            ProfileSettingsMenu(
              onEditPhysical: _openEditScreen, // 🌟 Usamos la nueva función
              onEditNutritional:
                  _openNutritionalPreferencesSheet, // El de alergias se queda como BottomSheet
            ),
            const SizedBox(height: 20),
            ProfileSystemMenu(onLogout: _logout),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
