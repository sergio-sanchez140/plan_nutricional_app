import 'package:flutter/material.dart';

class AiFeedbackDialog extends StatelessWidget {
  final Map<String, dynamic> iaData;

  const AiFeedbackDialog({super.key, required this.iaData});

  static Future<void> show(BuildContext context, Map<String, dynamic> iaData) {
    return showDialog(
      context: context,
      builder: (context) => AiFeedbackDialog(iaData: iaData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calorias = iaData['calorias'] ?? 0;
    final macros = iaData['macros'] ?? {};

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Column(
        children: [
          Icon(Icons.auto_awesome, color: Colors.amber, size: 48),
          SizedBox(height: 10),
          Text("¡Comida registrada!", textAlign: TextAlign.center),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "La IA ha calculated $calorias kcal",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _macroBadge("P: ${macros['proteinas'] ?? macros['proteinas_g'] ?? 0}g", Colors.red),
              _macroBadge("C: ${macros['carbohidratos'] ?? macros['carbohidratos_g'] ?? 0}g", Colors.blue),
              _macroBadge("G: ${macros['grasas'] ?? macros['grasas_g'] ?? 0}g", Colors.orange),
            ],
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            minimumSize: const Size(double.infinity, 45),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Genial",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _macroBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}