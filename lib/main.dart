// Archivo: lib/main.dart
import 'package:flutter/material.dart';
import 'package:plan_nutricional_app/providers/meal_plan_provider.dart';
import 'package:plan_nutricional_app/widgets/common/friendly_error_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plan_nutricional_app/services/notification_service.dart';
import 'package:plan_nutricional_app/screens/profile_setup_wizard.dart';
import 'screens/dashboard.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/challenges.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'package:provider/provider.dart';
import 'package:plan_nutricional_app/providers/progress_provider.dart';

void main() async {
  // 🌟 CAMBIO 2: Esto es obligatorio si haces llamadas a código nativo (como las notificaciones) antes del runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 🛡️ ESCUDO ANTI PANTALLAS ROJAS DE FLUTTER
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Si estamos en desarrollo, imprimimos el error en consola para nosotros
    debugPrint("🚨 Error capturado por escudo global: ${details.exception}");

    return Scaffold(
      body: FriendlyErrorState(
        title: "¡Ups! Un pequeño tropiezo 🛠️",
        message:
            "Algo se ha enredado en nuestros cables internos. Estamos trabajando para solucionarlo.",
        icon: Icons.engineering_rounded,
        onRetry: () {
          // Aquí no podemos hacer mucho más que invitar a reiniciar,
          // pero evitamos que la app parezca un "hackeo".
        },
      ),
    );
  };

  // 🌟 CAMBIO 3: Arrancamos el motor y las zonas horarias
  await NotificationService().init();

  runApp(
    // 🚀 MultiProvider inyecta el cerebro central a toda la app
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      Dashboard(onTabSelected: (index) => setState(() => _currentTab = index)),
      MealPlanScreen(
        onTabSelected: (index) => setState(() => _currentTab = index),
      ),
      const ChallengesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentTab, children: tabs),
      // 🔥 AQUÍ ESTABA EL BOTÓN FLOTANTE VIEJO QUE TAPABA AL NUEVO. ¡FUE ELIMINADO! 🔥
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
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
