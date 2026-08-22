import 'package:flutter/material.dart';

class ProfileWarningCard extends StatelessWidget {
  final Function(int)? onTabSelected;

  const ProfileWarningCard({super.key, this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange[50],
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.orange),
        title: const Text("Tu perfil está incompleto"),
        subtitle: const Text("Completa tus datos para personalizar tu plan"),
        trailing: ElevatedButton(
          child: const Text("Completar"),
          onPressed: () {
            if (onTabSelected != null) {
              onTabSelected!(3);
            }
          },
        ),
      ),
    );
  }
}
