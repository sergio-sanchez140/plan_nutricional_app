import 'package:flutter/material.dart';

class ReplacingOverlay extends StatelessWidget {
  const ReplacingOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                'https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExcXZnc3Npcmw2dzVuMXduemF4YjFoYm04eHo1M2FoZjVpc21idzVtcyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9dHM/5oaWdgMNnLTrTSra4E/giphy.gif',
                height: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                "🪄 Haciendo magia con tu menú...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.yellowAccent,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}