import 'package:flutter/material.dart';
import 'package:plan_nutricional_app/screens/profile_setup_wizard.dart';
import 'screens/dashboard.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/challenges_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding.dart';
import 'screens/login.dart';
import 'screens/register_data.dart';

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
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Arial'),
      // Pantalla inicial
      home: const OnboardingScreen(),
      // Rutas nombradas
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterDataScreen(),
        '/main': (context) => const MainScreen(), // tabs
        '/profileSetup': (context) =>
            const ProfileSetupWizard(), // <-- nuevo wizard
      },
    );
  }
}

// Pantalla principal con BottomNavigationBar
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _tabs = [
      Dashboard(
        onTabSelected: (index) {
          setState(() {
            _currentTab = index;
          });
        },
      ),
      const MealPlanScreen(),
      const ChallengesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: _tabs[_currentTab],
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
            label: 'Plan de comidas',
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
