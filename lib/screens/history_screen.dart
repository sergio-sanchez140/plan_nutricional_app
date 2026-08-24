import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Pedimos al cerebro que cargue el historial al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().fetchHistory();
    });
  }

  // Traductor de estados a colores UX
  Color _getStatusColor(String status) {
    switch (status) {
      case 'perfect':
        return Colors.green.shade500; // Lo clavó
      case 'good':
        return Colors.lightGreen.shade300; // Casi lo clava
      case 'missed':
        return Colors.orange.shade400; // Se pasó o no llegó
      case 'empty':
      default:
        return Colors.grey.shade200; // No hizo nada
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Mi Progreso", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: provider.isLoadingHistory
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌟 WIDGET 1: Gamificación (Rachas)
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: "Racha Actual",
                          value: "${provider.currentStreak} días",
                          icon: Icons.local_fire_department,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: "Días Perfectos",
                          value: "${provider.perfectDays}",
                          icon: Icons.star_rounded,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 🌟 WIDGET 2: El Mapa de Calor (Heatmap)
                  const Text(
                    "Últimos 30 días",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 1)],
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: provider.heatMapData.map((dayData) {
                        final color = _getStatusColor(dayData['status']);
                        final dateParts = dayData['fecha'].toString().split('-');
                        final dayNumber = dateParts.length == 3 ? dateParts[2] : "";

                        return Tooltip(
                          message: "${dayData['fecha']} - ${dayData['calorias']} kcal",
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: dayData['status'] == 'empty' ? Colors.grey.shade300 : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                dayNumber,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: dayData['status'] == 'empty' ? Colors.grey.shade500 : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Leyenda UX
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(Colors.green.shade500, "Perfecto"),
                      const SizedBox(width: 12),
                      _buildLegendItem(Colors.lightGreen.shade300, "Bien"),
                      const SizedBox(width: 12),
                      _buildLegendItem(Colors.orange.shade400, "Desvío"),
                    ],
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}