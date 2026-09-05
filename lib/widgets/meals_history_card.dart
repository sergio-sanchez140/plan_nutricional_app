import 'package:flutter/material.dart';
import '../utils/meal_sorter.dart';

class MealsHistoryCard extends StatelessWidget {
  final List<String> historial;
  final List<String> turnosPendientes;
  final bool isCalorieLimitReached;
  final Function(String) onPendingMealTap; // 🌟 NUEVO: Callback específico

  const MealsHistoryCard({
    super.key,
    required this.historial,
    required this.turnosPendientes,
    required this.isCalorieLimitReached,
    required this.onPendingMealTap,
  });

  @override
  Widget build(BuildContext context) {
    if (historial.isEmpty && turnosPendientes.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Map<String, dynamic>> timeline = [];

    for (var turno in historial) timeline.add({'nombre': turno, 'completado': true});
    for (var turno in turnosPendientes) timeline.add({'nombre': turno, 'completado': false});

    // 🌟 Usamos nuestra fuente de la verdad (MealSorter)
    timeline.sort((a, b) {
      final ordenA = MealSorter.getCategoryOrder(a['nombre']);
      final ordenB = MealSorter.getCategoryOrder(b['nombre']);
      return ordenA.compareTo(ordenB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tu día de hoy",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          elevation: 0,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: timeline.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1, indent: 54, endIndent: 16, color: Color(0xFFF0F0F0),
            ),
            itemBuilder: (context, index) {
              final item = timeline[index];
              final rawNombre = item['nombre'] as String;
              final nombreTurno = rawNombre.isNotEmpty 
                  ? rawNombre[0].toUpperCase() + rawNombre.substring(1) 
                  : "Turno extra";
              final isCompleted = item['completado'] as bool;

              // 1️⃣ CASO COMPLETADO (No es clickeable, solo lectura)
              if (isCompleted) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.check_circle, color: Colors.green, size: 26),
                  title: Text(nombreTurno, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                );
              }

              // 2️⃣ CASO PENDIENTE (Límite superado)
              if (isCalorieLimitReached) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.nightlight_round, color: Colors.amber.shade400, size: 18),
                  ),
                  title: Text(nombreTurno, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
                  subtitle: Text("Tanque lleno. Mejor un té 🍵", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                );
              }

              // 3️⃣ CASO PENDIENTE NORMAL (🌟 Clickeable, sin botón feo)
              return InkWell(
                onTap: () => onPendingMealTap(rawNombre), // Saltamos al tab
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(Icons.radio_button_unchecked, color: Colors.grey.shade300, size: 26),
                  title: Text(nombreTurno, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                  // 🌟 Flecha sutil en lugar de un botón chillón
                  trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}