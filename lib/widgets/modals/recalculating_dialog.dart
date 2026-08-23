import 'dart:async';
import 'package:flutter/material.dart';

class RecalculatingDialog extends StatefulWidget {
  const RecalculatingDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Evita que el usuario lo cierre tocando fuera
      barrierColor: Colors.black.withOpacity(0.6), // Fondo oscuro elegante
      builder: (_) => const PopScope(
        canPop: false, // Evita que se cierre con el botón de atrás de Android
        child: RecalculatingDialog(),
      ),
    );
  }

  static void hide(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  State<RecalculatingDialog> createState() => _RecalculatingDialogState();
}

class _RecalculatingDialogState extends State<RecalculatingDialog> {
  int _currentIndex = 0;
  Timer? _timer;

  // 🧠 Textos que rotarán para entretener y dar feedback al usuario
  final List<String> _phrases = [
    "Analizando tu comida...",
    "Cuadrando tus macros...",
    "Ajustando calorías restantes...",
    "Reorganizando tu menú de hoy...",
    "Guardando en tu diario...",
  ];

  @override
  void initState() {
    super.initState();
    // Cambia la frase cada 1.5 segundos
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _phrases.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Colors.green,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              "IA Trabajando",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Animación suave de transición de texto
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _phrases[_currentIndex],
                key: ValueKey<int>(_currentIndex),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}