// Archivo: lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plan_nutricional_app/screens/profile_setup_wizard.dart';
import 'services/api_client.dart'; // Importante para la IA

import 'screens/dashboard.dart'; // Apuntamos al archivo correcto
import 'screens/meal_plan_screen.dart';
import 'screens/challenges.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding.dart';
import 'screens/login.dart';
import 'screens/register_data.dart';
import 'screens/register.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plan Nutricional IA',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/profileSetup': (context) => const ProfileSetupWizard(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (!mounted) return;

    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _isLoggedIn ? const MainScreen() : const OnboardingScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTab = 0;

  // 1. CREAMOS LA LLAVE (Walkie-Talkie)
  final GlobalKey<DashboardState> _dashboardKey =
      GlobalKey<DashboardState>(); // <--- NUEVO

  // Feedback visual tras el registro exitoso
  void _showAIFeedbackDialog(Map<String, dynamic> iaData) {
    final calorias = iaData['calorias'] ?? 0;
    final macros = iaData['macros'] ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 48),
            const SizedBox(height: 10),
            const Text("¡Comida registrada!", textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "La IA ha calculado $calorias kcal",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _macroBadge("P: ${macros['proteinas_g']}g", Colors.red),
                _macroBadge("C: ${macros['carbohidratos_g']}g", Colors.blue),
                _macroBadge("G: ${macros['grasas_g']}g", Colors.orange),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: () {
              Navigator.pop(context);
              _dashboardKey.currentState?.fetchInitialData();
            },
            child: const Text(
              "Genial",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Abre el panel para registrar ingesta libre por IA
  void _openAIFoodLogger() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FreeIntakeSheet(
            onSuccess: (iaData) {
              _showAIFeedbackDialog(iaData);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      Dashboard(
        key: _dashboardKey,
        onTabSelected: (index) {
          setState(() {
            _currentTab = index;
          });
        },
      ),
      // 👇 MIRA EL CAMBIO AQUÍ 👇
      MealPlanScreen(
        onTabSelected: (index) {
          setState(() {
            _currentTab = index;
          });
        },
      ),
      const ChallengesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentTab, children: tabs),

      floatingActionButton: _currentTab == 0
          ? FloatingActionButton.extended(
              onPressed: _openAIFoodLogger,
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text(
                "Comida Extra",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green[600],
              elevation: 4,
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        selectedItemColor: Colors.green[400],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Mi Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Retos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET: PANEL INFERIOR PARA REGISTRO LIBRE POR IA
// ============================================================================
class FreeIntakeSheet extends StatefulWidget {
  final Function(Map<String, dynamic> analysis) onSuccess;

  const FreeIntakeSheet({super.key, required this.onSuccess});

  @override
  _FreeIntakeSheetState createState() => _FreeIntakeSheetState();
}

class _FreeIntakeSheetState extends State<FreeIntakeSheet> {
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
      final response = await ApiClient.post(
        '/ai/intakes',
        body: {"texto_ingesta": text},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true && data['analisis_ia'] != null) {
          if (mounted) Navigator.pop(context);
          widget.onSuccess(data['analisis_ia']);
        } else {
          setState(
            () => _errorMsg = "La IA no devolvió el análisis correctamente.",
          );
        }
      } else {
        setState(
          () => _errorMsg = "Error en el servidor (${response.statusCode}).",
        );
      }
    } catch (e) {
      setState(() => _errorMsg = "Revisa tu conexión a internet.");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              hintText:
                  "Ej: Dos porciones de pizza barbacoa y una cola zero...",
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.green.shade400, width: 2),
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
    );
  }
}
