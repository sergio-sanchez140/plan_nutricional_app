import 'dart:async';
import 'package:flutter/material.dart';

class LoadingAiDialog extends StatefulWidget {
  final String title;
  final List<String> texts;

  const LoadingAiDialog({super.key, required this.title, required this.texts});

  // 🌟 Ahora podemos llamarlo pasándole el título y los textos que queramos
  static void show(
    BuildContext context, {
    required String title,
    required List<String> texts,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45, // Un fondo oscurecido elegante
      builder: (context) => LoadingAiDialog(title: title, texts: texts),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  State<LoadingAiDialog> createState() => _LoadingAiDialogState();
}

class _LoadingAiDialogState extends State<LoadingAiDialog> {
  Timer? _timer;
  int _textIndex = 0;

  @override
  void initState() {
    super.initState();
    // Cambiamos el texto cada 2.5 segundos
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted) {
        setState(() {
          if (_textIndex < widget.texts.length - 1) {
            _textIndex++;
          }
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono animado de la IA
            const Icon(Icons.auto_awesome, color: Colors.green, size: 36),
            const SizedBox(height: 24),

            // Spinner clásico
            const CircularProgressIndicator(
              color: Colors.green,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),

            // Título principal ("Analizando...")
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // 🌟 Los Textos rotativos de las fases
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: Text(
                widget.texts[_textIndex],
                key: ValueKey<int>(_textIndex),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
