import 'package:flutter/material.dart';
import '../modals/daily_history_bottom_sheet.dart';

class HeatmapCalendar extends StatelessWidget {
  final List<dynamic> heatMapData;

  const HeatmapCalendar({super.key, required this.heatMapData});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'perfect':
        return Colors.green.shade500;
      case 'good':
        return Colors.lightGreen.shade400;
      case 'missed':
        return Colors.orange.shade400;
      case 'empty':
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
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
                side: BorderSide(
                  color: isEmpty ? Colors.grey.shade300 : Colors.transparent,
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: isEmpty
                    ? null
                    : () => DailyHistoryBottomSheet.show(
                        context,
                        dayData['fecha'],
                      ),
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
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
