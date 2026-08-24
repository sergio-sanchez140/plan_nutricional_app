import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/history/history_widgets.dart'; // Importamos nuestros componentes limpios

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().fetchHistory();
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getInsightMessage(int streak, int perfectDays) {
    if (streak >= 7)
      return "¡Imparable! Tu cuerpo ya está notando los cambios. 🔥";
    if (streak >= 3) return "¡Vas por un camino excelente! Mantén el ritmo. 🚀";
    if (perfectDays >= 15)
      return "Mes increíble. Estás dominando tus hábitos. ⭐";
    if (perfectDays < 5)
      return "Semana de ajustes. ¡Hoy es un buen día para volver al verde! 🌱";
    return "Cada día es una nueva oportunidad. ¡A por todas! 💪";
  }

  void _shareProgress() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.white),
            SizedBox(width: 12),
            Text("Generando imagen para tus historias... 📸"),
          ],
        ),
        backgroundColor: Colors.purple.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final insightText = _getInsightMessage(
      provider.currentStreak,
      provider.perfectDays,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Mi Progreso",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: Colors.black87),
            onPressed: _shareProgress,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoadingHistory
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InsightCard(text: insightText),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: StreakCard(
                          streak: provider.currentStreak,
                          scaleAnimation: _scaleAnimation,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: "Días Perfectos",
                          value: "${provider.perfectDays}",
                          icon: Icons.star_rounded,
                          iconColor: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    "Últimos 30 días",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🌟 AHORA EL CALENDARIO ES INTERACTIVO
                  HeatmapCalendar(heatMapData: provider.heatMapData),
                  const SizedBox(height: 24),

                  const HeatmapLegend(),
                ],
              ),
            ),
    );
  }
}
