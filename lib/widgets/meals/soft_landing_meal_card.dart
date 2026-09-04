import 'package:flutter/material.dart';

class SoftLandingMealCard extends StatelessWidget {
  final String nombreComida; // Ej: "Cena" o "Merienda"

  const SoftLandingMealCard({
    super.key,
    required this.nombreComida,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blueGrey.shade100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono relajante
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              "🍵", // Taza de té/infusión
              style: TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          
          // Textos amigables
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      nombreComida,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Objetivo 100%",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Tu tanque de energía está lleno por hoy. Si tienes hambre, opta por una infusión, caldo ligero o gelatina 0%.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}