import 'package:flutter/material.dart';
import '../models/meal.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onReplace;
  final VoidCallback onToggleCompleted;

  const MealCard({
    Key? key,
    required this.meal,
    required this.onReplace,
    required this.onToggleCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                meal.image,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  if (meal.cantidad.isNotEmpty)
                    Text("Cantidad: ${meal.cantidad}"),
                  const SizedBox(height: 6),
                  Text(
                      "P: ${meal.protein}g  C: ${meal.carbs}g  F: ${meal.fat}g"),
                  const SizedBox(height: 6),
                  Text(
                    "Calorías: ${meal.calorias}",
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: onReplace,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Cambiar"),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(
                          meal.completed
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        onPressed: onToggleCompleted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}