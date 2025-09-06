import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({Key? key}) : super(key: key);

  @override
  _ChallengesScreenState createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final List<Map<String, dynamic>> challenges = [
    {"title": "Completa tu meta de proteína +5g", "progress": 0.6},
    {"title": "Bebe 2L de agua 💧", "progress": 0.8},
    {"title": "Camina 5000 pasos 🚶", "progress": 0.3},
  ];

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _completeChallenge(int index) {
    setState(() {
      challenges[index]["progress"] = 1.0;
    });
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: challenges
                .asMap()
                .entries
                .map((entry) => _challengeCard(entry.key, entry.value))
                .toList(),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: [Colors.green, Colors.orange, Colors.pink, Colors.blue],
            numberOfParticles: 20,
            gravity: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _challengeCard(int index, Map<String, dynamic> challenge) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge["title"],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: challenge["progress"],
              backgroundColor: Colors.grey[300],
              color: Colors.green,
              minHeight: 8,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (challenge["progress"] < 1.0)
                  ElevatedButton(
                    onPressed: () => _completeChallenge(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Completar"),
                  ),
                if (challenge["progress"] == 1.0)
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 28),
              ],
            )
          ],
        ),
      ),
    );
  }
}