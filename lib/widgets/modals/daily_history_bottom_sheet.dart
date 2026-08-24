import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';

class DailyHistoryBottomSheet extends StatelessWidget {
  final String date;

  const DailyHistoryBottomSheet({super.key, required this.date});

  // Método estático para invocarlo fácilmente desde cualquier lado
  static void show(BuildContext context, String date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que el modal ocupe más espacio si es necesario
      backgroundColor: Colors.transparent,
      builder: (context) => DailyHistoryBottomSheet(date: date),
    );
  }

  // Traductor de fechas a formato humano (ej: 2026-08-15 -> 15 de Ago)
  String _formatDateHuman(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return "${parts[2]} de ${months[int.parse(parts[1]) - 1]}";
    } catch (_) {
      return dateStr;
    }
  }

  // Icono dinámico según el turno
  IconData _getTurnoIcon(String turno) {
    switch (turno.toLowerCase()) {
      case 'desayuno': return Icons.wb_twilight_rounded;
      case 'almuerzo': return Icons.wb_sunny_rounded;
      case 'comida': return Icons.restaurant_rounded;
      case 'merienda': return Icons.coffee_rounded;
      case 'cena': return Icons.nights_stay_rounded;
      case 'snack': return Icons.cookie_rounded;
      default: return Icons.fastfood_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Píldora de arrastre (Grabber)
          const SizedBox(height: 12),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Resumen del día", style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(_formatDateHuman(date), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                // Badge de "Solo lectura" UX Rule #2
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text("Histórico", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Carga asíncrona mágica
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: DashboardService.getDailyHistoryDetail(date),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text("No se pudo cargar el detalle.\n${snapshot.error}", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)));
                }

                final data = snapshot.data!;
                final calorias = data['calorias_consumidas'] ?? 0;
                final meta = data['meta_calorias'] ?? 2000;
                final macros = data['macros'] ?? {};
                final List comidas = data['comidas'] ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de Calorías y Macros
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Calorías totales", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                Text("${calorias.toInt()} / ${meta.toInt()} kcal", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: calorias > meta ? Colors.orange.shade700 : Colors.green.shade700)),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMacroMini("Carbos", "${macros['carbohidratos_g'] ?? 0}g", Colors.blue),
                                _buildMacroMini("Proteína", "${macros['proteinas_g'] ?? 0}g", Colors.red),
                                _buildMacroMini("Grasas", "${macros['grasas_g'] ?? 0}g", Colors.orange),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Lista de Ingestas
                      const Text("Comidas registradas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      
                      if (comidas.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Center(child: Text("No hay detalles de comidas para este día.", style: TextStyle(color: Colors.grey.shade500))),
                        )
                      else
                        ...comidas.map((c) => _buildMealRow(c)).toList(),
                        
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroMini(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMealRow(Map<String, dynamic> comida) {
    final turno = comida['turno'] ?? 'extra';
    final nombre = comida['nombre'] ?? 'Desconocido';
    final kcal = comida['calorias'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(_getTurnoIcon(turno), color: Colors.green.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(turno.toString().toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text("${kcal.toInt()} kcal", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}