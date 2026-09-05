import 'package:flutter/material.dart';

class ProfileIncompleteAlert {
  static void show({
    required BuildContext context,
    required String message,
    required List<String> missingFields,
    Function(int)? onTabSelected,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Perfil incompleto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 10),
            const Text("Campos faltantes:"),
            const SizedBox(height: 5),
            ...missingFields.map((f) => Text("• $f")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              if (onTabSelected != null) onTabSelected(3);
            },
            child: const Text(
              "Completar perfil",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
