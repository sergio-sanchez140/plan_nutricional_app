import 'package:flutter/material.dart';
import '../macro_chip.dart';

class AiResultBottomSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  final int intentosRestantes;
  final List<dynamic> turnosPendientes; // <-- NUEVO

  const AiResultBottomSheet({
    super.key,
    required this.data,
    required this.intentosRestantes,
    required this.turnosPendientes, // <-- NUEVO
  });

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required Map<String, dynamic> data,
    required int intentosRestantes,
    required List<dynamic> turnosPendientes, // <-- NUEVO
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiResultBottomSheet(
        data: data,
        intentosRestantes: intentosRestantes,
        turnosPendientes: turnosPendientes,
      ),
    );
  }

  @override
  State<AiResultBottomSheet> createState() => _AiResultBottomSheetState();
}

class _AiResultBottomSheetState extends State<AiResultBottomSheet> {
  // Diccionario para guardar qué marcó en cada turno: {'desayuno': 'completado', 'almuerzo': 'saltado'}
  final Map<String, String> _estadoPendientes = {};

  @override
  Widget build(BuildContext context) {
    final macros = widget.data['macros'] ?? {};
    final ingredientes = List<String>.from(widget.data['ingredientes'] ?? []);

    // El botón se habilita SOLO si contestó a todos los turnos pendientes
    final bool todosResueltos =
        _estadoPendientes.length == widget.turnosPendientes.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.data['nombre_plato'] ?? 'Desconocido',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "🔥 ${widget.data['calorias'] ?? 0} kcal",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MacroChip(
                label: "Proteínas",
                value: "${macros['proteinas'] ?? macros['proteinas_g'] ?? 0}g",
                color: Colors.red,
              ),
              MacroChip(
                label: "Carbos",
                value:
                    "${macros['carbohidratos'] ?? macros['carbohidratos_g'] ?? 0}g",
                color: Colors.blue,
              ),
              MacroChip(
                label: "Grasas",
                value: "${macros['grasas'] ?? macros['grasas_g'] ?? 0}g",
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 🌟 INLINE SMART CHECKLIST (Solo se muestra si hay pendientes)
          if (widget.turnosPendientes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Ajuste de plan diario",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Tienes comidas planificadas anteriores sin confirmar. ¿Qué hiciste con ellas?",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),

                  // Generamos la lista de comidas pendientes dinámicamente
                  ...widget.turnosPendientes.map(
                    (turno) => _buildPendingMealRow(turno),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // BOTÓN CONFIRMAR (Deshabilitado si faltan respuestas)
          ElevatedButton(
            onPressed: todosResueltos
                ? () {
                    Navigator.pop(context, {
                      'action': 'confirm',
                      'resoluciones':
                          _estadoPendientes, // Mandamos el mapa de vuelta
                    });
                  }
                : null, // 🔥 Si no ha respondido todo, el botón se queda en gris
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              "¡Me lo he comido!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: todosResueltos ? Colors.white : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (widget.intentosRestantes > 0)
            TextButton(
              onPressed: () => Navigator.pop(context, {'action': 'retry'}),
              child: Text(
                "Volver a escanear (${widget.intentosRestantes} restantes)",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 🧩 Componente visual para cada comida pendiente
  Widget _buildPendingMealRow(dynamic turnoInfo) {
    final String idTurno = turnoInfo['turno'];
    final String nombre = turnoInfo['nombre'] ?? idTurno;
    final String? estadoActual = _estadoPendientes[idTurno];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "• ${nombre[0].toUpperCase()}${nombre.substring(1)}",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          // Botón: Me lo comí
          GestureDetector(
            onTap: () =>
                setState(() => _estadoPendientes[idTurno] = 'completado'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: estadoActual == 'completado'
                    ? Colors.green
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: estadoActual == 'completado'
                      ? Colors.green
                      : Colors.grey.shade300,
                ),
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: estadoActual == 'completado'
                    ? Colors.white
                    : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botón: Lo salté
          GestureDetector(
            onTap: () => setState(() => _estadoPendientes[idTurno] = 'saltado'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: estadoActual == 'saltado' ? Colors.red : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: estadoActual == 'saltado'
                      ? Colors.red
                      : Colors.grey.shade300,
                ),
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: estadoActual == 'saltado' ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
