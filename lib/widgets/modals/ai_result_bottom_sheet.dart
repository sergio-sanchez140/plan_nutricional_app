import 'package:flutter/material.dart';
import '../macro_chip.dart';

class AiResultBottomSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final int intentosRestantes;

  const AiResultBottomSheet({
    super.key,
    required this.data,
    required this.intentosRestantes,
  });

  static Future<String?> show({
    required BuildContext context,
    required Map<String, dynamic> data,
    required int intentosRestantes,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiResultBottomSheet(
        data: data,
        intentosRestantes: intentosRestantes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final macros = data['macros'] ?? {};
    final ingredientes = List<String>.from(data['ingredientes'] ?? []);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            data['nombre_plato'] ?? 'Desconocido',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "🔥 ${data['calorias'] ?? 0} kcal",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MacroChip(label: "Proteínas", value: "${macros['proteinas'] ?? 0}g", color: Colors.red),
              MacroChip(label: "Carbos", value: "${macros['carbohidratos'] ?? 0}g", color: Colors.blue),
              MacroChip(label: "Grasas", value: "${macros['grasas'] ?? 0}g", color: Colors.amber),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Ingredientes detectados:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...ingredientes.map(
            (ing) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ing)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // BOTÓN CONFIRMAR
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              "¡Me lo he comido!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),

          // BOTÓN REINTENTAR
          if (intentosRestantes > 0)
            TextButton(
              onPressed: () => Navigator.pop(context, 'retry'),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(
                "Volver a escanear ($intentosRestantes intentos restantes)",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}