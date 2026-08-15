import 'dart:typed_data';
import 'package:flutter/material.dart';

class PhotoConfirmationDialog extends StatelessWidget {
  final Uint8List imageBytes;

  const PhotoConfirmationDialog({super.key, required this.imageBytes});

  static Future<bool?> show(BuildContext context, Uint8List imageBytes) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PhotoConfirmationDialog(imageBytes: imageBytes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "¿Se ve bien la comida?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                imageBytes,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Asegúrate de que el plato está enfocado e iluminado para que la IA no se equivoque.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, false), // Repetir
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                    label: const Text("Repetir", style: TextStyle(color: Colors.black87)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true), // Analizar
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    label: const Text("Analizar", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}