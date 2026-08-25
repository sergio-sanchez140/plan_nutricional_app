// Archivo: lib/widgets/profile/profile_widgets.dart
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

// ----------------------------------------------------------------------
// 1. TARJETA DE IDENTIDAD (Avatar, Nombre, Peso, Objetivo)
// ----------------------------------------------------------------------
class ProfileIdentityCard extends StatelessWidget {
  final String name;
  final String goal;
  final double weight;
  final String? avatarUrl;
  final bool isUploadingPicture;
  final VoidCallback onPickImage;

  const ProfileIdentityCard({
    super.key,
    required this.name,
    required this.goal,
    required this.weight,
    required this.avatarUrl,
    required this.isUploadingPicture,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              onTap: isUploadingPicture ? null : onPickImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green.shade300, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                      child: avatarUrl == null ? Icon(Icons.person, size: 40, color: Colors.green.shade200) : null,
                    ),
                  ),
                  if (isUploadingPicture)
                    Container(
                      width: 86, height: 86,
                      decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      ),
                    ),
                  if (!isUploadingPicture)
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
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
                  Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      goal.toString().toUpperCase(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("Peso actual: ${weight.toStringAsFixed(1)} kg", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 2. TARJETA DE GAMIFICACIÓN (Sustituye al spinner inventado)
// ----------------------------------------------------------------------
class ProfileGamificationCard extends StatelessWidget {
  final int level;
  final int xp;
  final int streak;

  const ProfileGamificationCard({
    super.key,
    required this.level,
    required this.xp,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(Icons.military_tech_rounded, Colors.purple, "Nivel", "$level"),
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            _buildStatItem(Icons.auto_awesome_rounded, Colors.blue, "Experiencia", "$xp XP"),
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            _buildStatItem(Icons.local_fire_department_rounded, Colors.orange, "Racha", "$streak días"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// 3. TARJETA DE MENÚ DE CONFIGURACIÓN
// ----------------------------------------------------------------------
class ProfileSettingsMenu extends StatelessWidget {
  final VoidCallback onEditPhysical;
  final VoidCallback onEditNutritional;

  const ProfileSettingsMenu({super.key, required this.onEditPhysical, required this.onEditNutritional});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text("Configuración de tu Plan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 2,
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(Icons.person_outline, color: Colors.blue.shade600)),
                title: const Text("Datos físicos y objetivo", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Edad, peso, altura, actividad..."),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: onEditPhysical,
              ),
              const Divider(height: 1, indent: 70, endIndent: 20),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.orange.shade50, child: Icon(Icons.restaurant_menu, color: Colors.orange.shade600)),
                title: const Text("Gustos y Restricciones", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Alergias, dietas, alimentos favoritos..."),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: onEditNutritional,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// 4. TARJETA DE SISTEMA (Cerrar sesión)
// ----------------------------------------------------------------------
class ProfileSystemMenu extends StatelessWidget {
  final VoidCallback onLogout;
  const ProfileSystemMenu({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.red.shade50, child: Icon(Icons.logout, color: Colors.red.shade400)),
        title: const Text("Cerrar sesión", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onLogout,
      ),
    );
  }
}