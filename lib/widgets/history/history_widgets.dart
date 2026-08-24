import 'package:flutter/material.dart';
import '../modals/daily_history_bottom_sheet.dart';

// ----------------------------------------------------------------------
// 1. EL COACH EMOCIONAL
// ----------------------------------------------------------------------
class InsightCard extends StatelessWidget {
  final String text;
  const InsightCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_rounded, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 2. TARJETAS DE ESTADÍSTICAS (Racha y Perfectos)
// ----------------------------------------------------------------------
class StreakCard extends StatelessWidget {
  final int streak;
  final Animation<double> scaleAnimation;

  const StreakCard({super.key, required this.streak, required this.scaleAnimation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScaleTransition(
            scale: scaleAnimation,
            child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text("$streak días", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text("Racha Actual", style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const StatCard({super.key, required this.title, required this.value, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 15, spreadRadius: 1, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.black87.withOpacity(0.6), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 3. EL MAPA DE CALOR INTERACTIVO (LA MAGIA UX)
// ----------------------------------------------------------------------
class HeatmapCalendar extends StatelessWidget {
  final List<dynamic> heatMapData;

  const HeatmapCalendar({super.key, required this.heatMapData});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'perfect': return Colors.green.shade500;
      case 'good': return Colors.lightGreen.shade400;
      case 'missed': return Colors.orange.shade400;
      case 'empty':
      default: return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 15, spreadRadius: 1, offset: const Offset(0, 5))],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: heatMapData.map((dayData) {
          final color = _getStatusColor(dayData['status']);
          final dateParts = dayData['fecha'].toString().split('-');
          final dayNumber = dateParts.length == 3 ? dateParts[2] : "";
          final bool isEmpty = dayData['status'] == 'empty';

          return Tooltip(
            message: isEmpty ? "Sin registros" : "Ver detalle del día",
            child: Material(
              color: color,
              shape: CircleBorder(
                side: BorderSide(color: isEmpty ? Colors.grey.shade300 : Colors.transparent, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              // 🌟 AQUÍ ESTÁ LA INTERACCIÓN
              child: InkWell(
                onTap: isEmpty ? null : () => DailyHistoryBottomSheet.show(context, dayData['fecha']),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: Text(
                      dayNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isEmpty ? Colors.grey.shade400 : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 4. LEYENDA DEL MAPA DE CALOR
// ----------------------------------------------------------------------
class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.green.shade500, "Perfecto"),
        const SizedBox(width: 12),
        _buildLegendItem(Colors.lightGreen.shade400, "Bien"),
        const SizedBox(width: 12),
        _buildLegendItem(Colors.orange.shade400, "Desvío"),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }
}