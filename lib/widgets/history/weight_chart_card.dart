import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
// Asegúrate de que esta ruta a tu provider sea la correcta
import '../../providers/progress_provider.dart'; 

class WeightChartCard extends StatelessWidget {
  final List<dynamic> weightData;
  final Map<String, dynamic> weightSummary;

  const WeightChartCard({super.key, required this.weightData, required this.weightSummary});

  @override
  Widget build(BuildContext context) {
    if (weightData.isEmpty || weightData.length < 2) return const SizedBox.shrink();

    final List<FlSpot> spots = [];
    double minWeight = double.infinity;
    double maxWeight = -double.infinity;

    for (int i = 0; i < weightData.length; i++) {
      final double weight = (weightData[i]['peso'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), weight));
      if (weight < minWeight) minWeight = weight;
      if (weight > maxWeight) maxWeight = weight;
    }

    minWeight = minWeight - 1.0;
    maxWeight = maxWeight + 1.0;

    final currentWeight = weightSummary['peso_actual'] ?? weightData.last['peso'];
    final double diff = (weightSummary['diferencia_total_kg'] as num?)?.toDouble() ?? 0.0;

    final bool isLosing = diff < 0;
    final diffColor = isLosing ? Colors.green.shade700 : Colors.red.shade500;
    final diffBgColor = isLosing ? Colors.green.shade50 : Colors.red.shade50;
    final diffIcon = isLosing ? Icons.trending_down : Icons.trending_up;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Evolución de Peso", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              Row(
                children: [
                  if (diff != 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: diffBgColor, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(diffIcon, color: diffColor, size: 14),
                          const SizedBox(width: 4),
                          Text("${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg", style: TextStyle(fontWeight: FontWeight.bold, color: diffColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  Text("$currentWeight kg", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showAddWeightDialog(context, currentWeight.toDouble()),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                      child: Icon(Icons.add, size: 20, color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: minWeight,
                maxY: maxWeight,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(colors: [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context, double currentWeight) {
    final TextEditingController ctrl = TextEditingController(text: currentWeight.toString());
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Registrar Peso", textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Añade tu peso de hoy. Usa la misma báscula y a la misma hora para mayor precisión.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(suffixText: "kg", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: isSaving ? null : () async {
                  final val = double.tryParse(ctrl.text.replaceAll(',', '.'));
                  if (val != null && val > 0 && val <= 300) {
                    setState(() => isSaving = true);
                    final success = await ctx.read<ProgressProvider>().logWeight(val);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(success ? "Peso registrado 🚀" : "Error al registrar"), backgroundColor: success ? Colors.green : Colors.red));
                    }
                  }
                },
                child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Guardar", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }
}