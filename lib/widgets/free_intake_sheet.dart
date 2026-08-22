import 'package:flutter/material.dart';
import '../services/dashboard_service.dart'; // 🚀 Importamos nuestro servicio unificado

class FreeIntakeSheet extends StatefulWidget {
  final Function(Map<String, dynamic> analysis) onSuccess;
  const FreeIntakeSheet({super.key, required this.onSuccess});

  @override
  FreeIntakeSheetState createState() => FreeIntakeSheetState();
}

class FreeIntakeSheetState extends State<FreeIntakeSheet> {
  final TextEditingController _textCtrl = TextEditingController();
  bool _isProcessing = false;
  String _errorMsg = '';

  Future<void> _submitIntake() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMsg = '';
    });

    try {
      // 🚀 ¡Llamamos al NUEVO endpoint que solo analiza, NO guarda!
      final data = await DashboardService.analyzeText(text);
      
      if (mounted) {
        Navigator.pop(context); // 1. Cerramos el teclado y este modal
        widget.onSuccess(data); // 2. Mandamos la data al Dashboard para que abra el modal de Catch-up
      }
    } catch (e) {
      // Limpiamos el mensaje de error por si viene con la palabra "Exception:"
      setState(() => _errorMsg = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ Calculamos la altura de la pantalla para ponerle un tope al modal
    final screenHeight = MediaQuery.of(context).size.height;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.8, // Como mucho, el 80% de la pantalla
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        // 🛡️ Esto permite que si el teclado sube, la caja haga scroll por dentro
        child: SingleChildScrollView(
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    "Registro Inteligente",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Escribe lo que has comido. La IA calculará las calorías y macronutrientes automáticamente.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _textCtrl,
                enabled: !_isProcessing,
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Ej: Dos porciones de pizza barbacoa y una cola zero...",
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.green.shade400,
                      width: 2,
                    ),
                  ),
                ),
              ),
              if (_errorMsg.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMsg,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isProcessing ? null : _submitIntake,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Procesar comida",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}