import 'package:flutter/material.dart';
import '../../models/meal.dart';
import '../meal_card.dart';

class MealCategoryList extends StatelessWidget {
  final String categoryName;
  final List<Meal> meals;
  final bool isCalorieLimitReached;
  final Function(Meal) onReplace;
  final Function(Meal) onToggleCompleted;
  final List<Animation<Offset>> animations;
  final int startingAnimationIndex;

  const MealCategoryList({
    super.key,
    required this.categoryName,
    required this.meals,
    required this.isCalorieLimitReached,
    required this.onReplace,
    required this.onToggleCompleted,
    required this.animations,
    required this.startingAnimationIndex,
  });

  @override
  Widget build(BuildContext context) {
    final nombreTurno =
        categoryName[0].toUpperCase() + categoryName.substring(1);
    int localIndex = startingAnimationIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nombreTurno,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: meals.map((meal) {
            // 1. Instanciamos la tarjeta normal SIEMPRE
            Widget card = MealCard(
              meal: meal,
              onReplace: () => onReplace(meal),
              onToggleCompleted: () => onToggleCompleted(meal),
            );

            // 🌟 LÓGICA UX: Autonomía Guiada (El usuario manda)
            // Si nos hemos pasado de calorías y la comida NO está completada...
            if (isCalorieLimitReached && !meal.completed) {
              card = Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50, // Fondo de advertencia suave
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade200, width: 1.5),
                ),
                child: Column(
                  children: [
                    // Banner amigable arriba
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Text("🍵", style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Tanque de energía lleno. Si tienes hambre, opta por una infusión, pero tú decides.",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // La tarjeta real del usuario, un poco difuminada pero CLICKABLE
                    Opacity(
                      opacity: 0.75, // Efecto "disabled" visual que sugeriste
                      child: IgnorePointer(
                        ignoring:
                            false, // ¡CRUCIAL! Permite que se pueda hacer clic
                        child: card,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Si no hay límite, simplemente le ponemos su margen normal
              card = Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: card,
              );
            }

            // Aplicamos la animación
            if (localIndex < animations.length) {
              card = SlideTransition(
                position: animations[localIndex],
                child: card,
              );
              localIndex++;
            }

            return card;
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
