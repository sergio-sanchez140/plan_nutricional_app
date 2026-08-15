import 'package:flutter/material.dart';

class AIRecommendationCard extends StatelessWidget {
  final Animation<Offset> animation;
  final String message; // Opcional: Para cambiar el mensaje en el futuro

  const AIRecommendationCard({
    super.key,
    required this.animation,
    this.message =
        "Mantén un buen ritmo. Trata de cenar al menos 2 horas antes de ir a dormir 🌙",
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: animation,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.green[50],
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
