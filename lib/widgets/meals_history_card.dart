import 'package:flutter/material.dart';

class MealsHistoryCard extends StatelessWidget {
  final List<String> historial;
  final List<String> turnosPendientes;
  final bool isCalorieLimitReached;
  final VoidCallback onAddAction;

  const MealsHistoryCard({
    super.key,
    required this.historial,
    required this.turnosPendientes,
    required this.isCalorieLimitReached,
    required this.onAddAction,
  });

  // 🌟 HELPER BLINDADO: Atrapa cualquier variación de la palabra
  int _getOrdenTurno(String turno) {
    // Lo pasamos a minúsculas y le quitamos los espacios en blanco de los bordes
    final t = turno.toLowerCase().trim();

    if (t.contains('desayuno') || t.contains('breakfast')) return 10;

    if (t.contains('media mañana') ||
        t.contains('mañana') ||
        t.contains('snack 1'))
      return 20;

    if (t.contains('comida') || t.contains('lunch') || t.contains('almuerzo'))
      return 30;

    // 💥 AQUI ESTABA EL FALLO: Atrapamos merienda, tarde, snack, tentempié...
    if (t.contains('merienda') ||
        t.contains('snack') ||
        t.contains('tarde') ||
        t.contains('media tarde'))
      return 40;

    if (t.contains('cena') || t.contains('dinner')) return 50;

    return 60; // Cualquier otra cosa rara se va al fondo
  }

  @override
  Widget build(BuildContext context) {
    if (historial.isEmpty && turnosPendientes.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Map<String, dynamic>> timeline = [];

    // 1. Añadimos los completados
    for (var turno in historial) {
      timeline.add({'nombre': turno, 'completado': true});
    }

    // 2. Añadimos los pendientes
    for (var turno in turnosPendientes) {
      timeline.add({'nombre': turno, 'completado': false});
    }

    // 3. Ordenamos TODO cronológicamente con fuerza bruta
    timeline.sort((a, b) {
      final ordenA = _getOrdenTurno(a['nombre']);
      final ordenB = _getOrdenTurno(b['nombre']);
      return ordenA.compareTo(ordenB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tu día de hoy",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
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
              height: 1,
              indent: 54,
              endIndent: 16,
              color: Color(0xFFF0F0F0),
            ),
            itemBuilder: (context, index) {
              final item = timeline[index];
              final rawNombre = item['nombre'] as String;

              // Evitamos crasheos si el string viene vacío
              final nombreTurno = rawNombre.isNotEmpty
                  ? rawNombre[0].toUpperCase() + rawNombre.substring(1)
                  : "Turno extra";

              final isCompleted = item['completado'] as bool;

              // 1️⃣ CASO COMPLETADO
              if (isCompleted) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 26,
                  ),
                  title: Text(
                    nombreTurno,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                );
              }

              // 2️⃣ CASO PENDIENTE (Límite superado)
              if (isCalorieLimitReached) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.nightlight_round,
                      color: Colors.amber.shade400,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    nombreTurno,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    "Tanque lleno. Mejor un té o caldo 🍵",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                );
              }

              // 3️⃣ CASO PENDIENTE (Normal)
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.grey.shade300,
                  size: 26,
                ),
                title: Text(
                  nombreTurno,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                trailing: TextButton.icon(
                  onPressed: onAddAction,
                  icon: const Icon(Icons.add, size: 18, color: Colors.green),
                  label: const Text(
                    "Añadir",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
