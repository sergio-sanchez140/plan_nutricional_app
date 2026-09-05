import 'package:flutter/material.dart';
import '../macro_chip.dart';

class AiResultBottomSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  final int intentosRestantes;
  final List<dynamic> turnosPendientes;

  const AiResultBottomSheet({
    super.key,
    required this.data,
    required this.intentosRestantes,
    required this.turnosPendientes,
  });

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required Map<String, dynamic> data,
    required int intentosRestantes,
    required List<dynamic> turnosPendientes,
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
  final Map<String, String> _estadoPendientes = {};

  // 🌟 HELPER: Filtro temporal. Solo devuelve los turnos cuya hora YA PASÓ.
  List<dynamic> _getPastPendingMeals(List<dynamic> todasPendientes) {
    final int hour = DateTime.now().hour;

    return todasPendientes.where((turnoInfo) {
      final t = turnoInfo.toString().toLowerCase().trim();

      // El desayuno siempre es pasado si está pendiente
      if (t.contains('desayuno') || t.contains('breakfast')) return true;

      // El almuerzo/media mañana lo preguntamos si son más de las 11:00
      if (t.contains('media mañana') ||
          t.contains('mañana') ||
          t.contains('almuerzo'))
        return hour >= 11;

      // La comida la preguntamos si son más de las 15:00
      if (t.contains('comida') || t.contains('lunch')) return hour >= 15;

      // La merienda la preguntamos si son más de las 18:00
      if (t.contains('merienda') || t.contains('snack') || t.contains('tarde'))
        return hour >= 18;

      // La cena la preguntamos si son más de las 22:00
      if (t.contains('cena') || t.contains('dinner')) return hour >= 22;

      return true; // Por seguridad, si hay un nombre raro, lo mostramos
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final macros = widget.data['macros'] ?? {};
    final ingredientes = List<String>.from(widget.data['ingredientes'] ?? []);

    // 🌟 APLICAMOS EL FILTRO DE RELOJ BIOLÓGICO
    final turnosPasados = _getPastPendingMeals(widget.turnosPendientes);

    // Ahora solo exigimos que resuelva las comidas que realmente ya pasaron
    final bool todosResueltos =
        _estadoPendientes.length == turnosPasados.length;

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

          // 🚀 UX FIX: Restauramos la lista de ingredientes si la IA los detectó
          if (ingredientes.isNotEmpty) ...[
            const Text(
              "Ingredientes detectados:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            ...ingredientes.map(
              (ing) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(ing, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 🌟 INLINE SMART CHECKLIST (Extraído para limpieza)
          // 🌟 INLINE SMART CHECKLIST (Solo muestra lo pasado)
          if (turnosPasados.isNotEmpty) _buildSmartChecklist(turnosPasados),
          // BOTÓN CONFIRMAR
          ElevatedButton(
            onPressed: todosResueltos
                ? () {
                    Navigator.pop(context, {
                      'action': 'confirm',
                      'resoluciones': _estadoPendientes,
                    });
                  }
                : null,
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

          // BOTÓN REINTENTAR
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

  // =========================================================================
  // 🧩 WIDGETS EXTRAÍDOS (Clean Code)
  // =========================================================================

  // 🌟 EL FIX: Añadimos (List<dynamic> turnosPasados) aquí
  Widget _buildSmartChecklist(List<dynamic> turnosPasados) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
            ...turnosPasados.map((turno) => _buildPendingMealRow(turno)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingMealRow(dynamic turnoInfo) {
    // 🌟 CORRECCIÓN: turnoInfo es un String plano (ej: "desayuno")
    final String idTurno = turnoInfo.toString();

    // Capitalizamos la primera letra para que quede bonito (ej: "Desayuno")
    final String nombre = idTurno.isNotEmpty
        ? "${idTurno[0].toUpperCase()}${idTurno.substring(1)}"
        : "Turno pendiente";

    final String? estadoActual = _estadoPendientes[idTurno];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "• $nombre",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),

          // 🚀 Usamos el nuevo componente reutilizable
          _buildActionBtn(
            isSelected: estadoActual == 'completado',
            icon: Icons.check,
            activeColor: Colors.green,
            onTap: () =>
                setState(() => _estadoPendientes[idTurno] = 'completado'),
          ),
          const SizedBox(width: 8),
          _buildActionBtn(
            isSelected: estadoActual == 'saltado',
            icon: Icons.close,
            activeColor: Colors.red,
            onTap: () => setState(() => _estadoPendientes[idTurno] = 'saltado'),
          ),
        ],
      ),
    );
  }

  // 🧩 Componente genérico para los botones de Check/Cruz (DRY)
  Widget _buildActionBtn({
    required bool isSelected,
    required IconData icon,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}
