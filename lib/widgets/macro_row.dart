import 'package:flutter/material.dart';

// En tu nuevo archivo
class MacroRow extends StatelessWidget { // <-- Sin guión bajo
  final String label;
  final String value;
  final Color color;

  const MacroRow({ // <-- Sin guión bajo
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
