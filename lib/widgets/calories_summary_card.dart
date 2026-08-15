import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'macro_row.dart'; // Importamos tu widget del Nivel 1

class CaloriesSummaryCard extends StatelessWidget {
  final double consumidas;
  final double meta;
  final Map<String, dynamic> macros;

  const CaloriesSummaryCard({
    super.key,
    required this.consumidas,
    required this.meta,
    required this.macros,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculamos el porcentaje real para saber el color
    // Si la meta es 0 (para evitar dividir por cero por error), devolvemos 0
    final double porcentajeReal = meta > 0 ? consumidas / meta : 0.0;

    // 2. La barra visualmente no puede pasar del 100% (1.0)
    final double progresoVisual = porcentajeReal.clamp(0.0, 1.0);

    // 3. LA MAGIA UX: Lógica del Semáforo Suave
    Color colorProgreso;
    Color colorTexto;

    if (porcentajeReal < 0.85) {
      colorProgreso = Colors.green; // Zona Segura
      colorTexto = Colors.green.shade700;
    } else if (porcentajeReal <= 1.0) {
      colorProgreso =
          Colors.orange.shade400; // Zona de Aterrizaje (¡Cuidado con la cena!)
      colorTexto = Colors.orange.shade700;
    } else {
      colorProgreso = Colors.redAccent; // Te pasaste (Rojo suave)
      colorTexto = Colors.red.shade700;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 65.0,
              lineWidth: 12.0,
              percent: progresoVisual,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    consumidas.toInt().toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: colorTexto,
                    ),
                  ),
                  Text(
                    "/ ${meta.toInt()} kcal",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              progressColor: colorProgreso, // Aplicamos el color dinámico
              backgroundColor: Colors.grey.shade200,
              animation: true,
              animateFromLastPercent: true,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Progreso de Hoy",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  MacroRow(
                    label: "Carbos",
                    value: "${macros['carbohidratos_g']}g",
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 4),
                  MacroRow(
                    label: "Proteínas",
                    value: "${macros['proteinas_g']}g",
                    color: Colors.red,
                  ),
                  const SizedBox(height: 4),
                  MacroRow(
                    label: "Grasas",
                    value: "${macros['grasas_g']}g",
                    color: Colors.orange,
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
