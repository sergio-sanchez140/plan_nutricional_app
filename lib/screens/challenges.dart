// Archivo: lib/screens/challenges.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/api_client.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  _ChallengesScreenState createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  late ConfettiController _confettiController;

  bool _loading = true;

  // Datos del Jugador
  int nivel = 1;
  String titulo = "Iniciado";
  int xpActual = 0;
  int xpSiguienteNivel = 100;
  int rachaDias = 0;

  // Lista de Retos
  List<dynamic> retos = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _fetchGamificationData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _fetchGamificationData() async {
    setState(() => _loading = true);

    try {
      // 1. Pedimos el estado del jugador
      final statusRes = await ApiClient.get(
        '/gamification/status',
      ); // Añade /db/ si hace falta
      if (statusRes.statusCode == 200) {
        final data = jsonDecode(statusRes.body);
        nivel = data['nivel'] ?? 1;
        titulo = data['titulo'] ?? "Iniciado";
        xpActual = data['xp_actual'] ?? 0;
        xpSiguienteNivel = data['xp_siguiente_nivel'] ?? 100;
        rachaDias = data['racha_dias'] ?? 0;
      }

      // 2. Pedimos los retos dinámicos de hoy
      final retosRes = await ApiClient.get(
        '/ai/challenges',
      ); // Añade /db/ si hace falta
      if (retosRes.statusCode == 200) {
        retos = jsonDecode(retosRes.body);
      }
    } catch (e) {
      debugPrint("Error cargando gamificación: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completarReto(int retoId, int xpRecompensa) async {
    try {
      final res = await ApiClient.post(
        '/ai/challenges/complete', // Asegúrate de mantener tu prefijo
        body: {"id": retoId},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final bool subeNivel = data['sube_nivel'] ?? false;
        final String nuevoTitulo = data['nuevo_titulo'] ?? "";

        // Disparamos el confeti siempre
        _confettiController.play();

        if (subeNivel) {
          // ¡Subida de Nivel! Mostramos un popup épico
          _showLevelUpDialog(nuevoTitulo);
        } else {
          // Completado normal
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("¡Misión completada! +$xpRecompensa XP 🔥"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Recargamos los datos para ver la nueva barra y título
        await _fetchGamificationData();
      } else {
        _showError("No se pudo completar el reto.");
      }
    } catch (e) {
      _showError("Error de red al completar el reto.");
    }
  }

  // --- NUEVA FUNCIÓN: POPUP ÉPICO DE LEVEL UP ---
  void _showLevelUpDialog(String nuevoTitulo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.stars, color: Colors.amber, size: 60),
            SizedBox(height: 10),
            Text(
              "¡LEVEL UP!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.green,
              ),
            ),
          ],
        ),
        content: Text(
          "¡Enhorabuena! Has ascendido a:\n\n🏆 $nuevoTitulo",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "¡Aceptar!",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    double progresoXP = xpSiguienteNivel > 0
        ? (xpActual / xpSiguienteNivel).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Tus Misiones",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )
              : RefreshIndicator(
                  onRefresh: _fetchGamificationData,
                  color: Colors.green,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. TARJETA DEL JUGADOR ---
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade800,
                                  Colors.green.shade500,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.white24,
                                      child: Text(
                                        "Lvl $nivel",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            titulo,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.local_fire_department,
                                                color: Colors.orangeAccent,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "$rachaDias días de racha",
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                LinearPercentIndicator(
                                  lineHeight: 14.0,
                                  percent: progresoXP,
                                  backgroundColor: Colors.white30,
                                  progressColor: Colors.amber,
                                  barRadius: const Radius.circular(10),
                                  animation: true,
                                  animateFromLastPercent: true,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "$xpActual / $xpSiguienteNivel XP",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          "Misiones de hoy",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- 2. LISTA DE RETOS ---
                        if (retos.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                "¡No hay misiones por ahora! Come algo y la IA generará nuevas tareas.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: retos.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final reto = retos[index];
                              final bool completado =
                                  reto['completado'] ?? false;

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: completado
                                              ? Colors.green.shade50
                                              : Colors.blue.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          completado
                                              ? Icons.check_circle
                                              : Icons.star,
                                          color: completado
                                              ? Colors.green
                                              : Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reto['titulo'] ?? "Reto",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                decoration: completado
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              reto['descripcion'] ?? "",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "+${reto['xp_recompensa']} XP",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!completado)
                                        ElevatedButton(
                                          onPressed: () => _completarReto(
                                            reto['id'],
                                            reto['xp_recompensa'],
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black87,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            "Completar",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

          // --- 3. EL CAÑÓN DE CONFETI ---
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.orange,
                Colors.pink,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
