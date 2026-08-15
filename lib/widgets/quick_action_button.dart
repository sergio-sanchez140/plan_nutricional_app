import 'package:flutter/material.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int tabIndex;
  final Function(int)? onTabSelected; // <-- Añadimos la función como variable

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tabIndex,
    this.onTabSelected, // <-- La pedimos en el constructor
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 👇 MIRA AQUÍ: Ya no usamos "widget.", llamamos a la variable directamente
        if (onTabSelected != null) {
          onTabSelected!(tabIndex); 
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.green[100],
            child: Icon(icon, color: Colors.green[700]),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}