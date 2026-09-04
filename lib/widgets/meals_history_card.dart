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

  @override
  Widget build(BuildContext context) {
    // Si no hay nada que mostrar, ocultamos la tarjeta
    if (historial.isEmpty && turnosPendientes.isEmpty) {
      return const SizedBox.shrink();
    }

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
            // La suma de lo que ya comió + lo que le falta
            itemCount: historial.length + turnosPendientes.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 54, // Alineado con el texto, saltando el icono
              endIndent: 16,
              color: Color(0xFFF0F0F0),
            ),
            itemBuilder: (context, index) {
              // 1️⃣ PINTAMOS EL HISTORIAL (Comidas completadas)
              if (index < historial.length) {
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
                    historial[index],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                );
              }

              // 2️⃣ PINTAMOS LOS TURNOS PENDIENTES
              // Ajustamos el índice para leer de la segunda lista
              final pendingIndex = index - historial.length;
              final turno = turnosPendientes[pendingIndex];
              final nombreTurno = turno[0].toUpperCase() + turno.substring(1);

              // 🌟 CASO A: Límite superado (Soft Landing Minimalista)
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
                      decoration: TextDecoration.lineThrough, // Sutil tachado
                    ),
                  ),
                  subtitle: Text(
                    "Tanque lleno. Mejor un té o caldo 🍵",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                );
              }

              // 🟢 CASO B: Turno pendiente normal
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
