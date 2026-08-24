import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'macro_row.dart';

class CaloriesSummaryCard extends StatelessWidget {
  final double consumidas;
  final double meta;
  final Map<String, dynamic> macros;
  final VoidCallback? onTapHistory;

  const CaloriesSummaryCard({
    super.key,
    required this.consumidas,
    required this.meta,
    required this.macros,
    this.onTapHistory,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculamos el porcentaje real para saber el color
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
      colorProgreso = Colors.orange.shade400; // Zona de Aterrizaje
      colorTexto = Colors.orange.shade700;
    } else {
      colorProgreso = Colors.redAccent; // Te pasaste (Rojo suave)
      colorTexto = Colors.red.shade700;
    }

    // 🌟 4. NUEVO ENVOLTORIO UX PREMIUM
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24), // Un poco más curvo (estilo iOS)
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5), // Sombra más elegante cayendo hacia abajo
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias, // Contiene el efecto visual del toque
        child: InkWell(
          onTap: onTapHistory,
          highlightColor: Colors.green.withOpacity(0.05), // Brillo sutil al presionar
          splashColor: Colors.green.withOpacity(0.1), // Onda sutil
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // 🌟 5. EL NUEVO HEADER (AFFORDANCE)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Progreso de hoy",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    // Solo mostramos "Historial >" si nos pasaron la función de navegación
                    if (onTapHistory != null)
                      Row(
                        children: [
                          Text(
                            "Historial",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20), // Separador del header
                
                // 🌟 6. CONTENIDO CENTRAL (Círculo + Macros)
                Row(
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
                      progressColor: colorProgreso,
                      backgroundColor: Colors.grey.shade100, // Un gris un pelín más suave
                      animation: true,
                      animateFromLastPercent: true,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center, // Centramos los macros
                        children: [
                          MacroRow(
                            label: "Carbos",
                            value: "${macros['carbohidratos_g']}g",
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8), // Aumentamos un poco el espaciado
                          MacroRow(
                            label: "Proteínas",
                            value: "${macros['proteinas_g']}g",
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}