// Archivo: lib/screens/login.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final String _googleClientId =
      "440637752293-fb39kggcj2qkvb3uksiu55dbeso09oo9.apps.googleusercontent.com";

  Future<void> _loginNormal() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Por favor, rellena todos los campos.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.post(
        '/db/login', // Ajusta si tu ruta de login tradicional es diferente
        body: {"email": email, "password": password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveSessionAndNavigate(data['access_token'], email);
      } else {
        _showError("Credenciales incorrectas.");
      }
    } catch (e) {
      _showError("Error de conexión con el servidor.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      // 1. Inicializamos Google SignIn con el Client ID de Web
      final GoogleSignIn googleSignIn = GoogleSignIn(clientId: _googleClientId);

      // 2. Forzamos el logout previo para que siempre pregunte qué cuenta usar
      await googleSignIn.signOut();

      // 3. Abrimos el popup de Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // El usuario cerró el popup sin seleccionar cuenta
        setState(() => _isGoogleLoading = false);
        return;
      }

      // 4. Obtenemos los tokens de autenticación
      // 4. Obtenemos los tokens de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken; // <-- NUEVO

      // Si tenemos CUALQUIERA de los dos, seguimos adelante
      if (idToken != null || accessToken != null) {
        
        final response = await ApiClient.post(
          '/db/login/google',
          body: {
            "id_token": idToken ?? "", 
            "access_token": accessToken ?? "" // <-- Enviamos el access_token al backend
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          // 6. Guardamos el JWT de tu backend y entramos
          await _saveSessionAndNavigate(data['access_token'], data['email']);
        } else {
          _showError(
            "El servidor rechazó el token de Google (${response.statusCode})",
          );
          await googleSignIn.signOut();
        }
      } else {
        _showError("No se pudo obtener el token de Google.");
      }
    } catch (e) {
      _showError("Error al conectar con Google. Verifica tu Client ID.");
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _saveSessionAndNavigate(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setString('user_email', email);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.restaurant_menu, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                "Bienvenido de nuevo",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              // Campos de Login tradicional
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // Botón Login Normal
              ElevatedButton(
                onPressed: _isLoading || _isGoogleLoading ? null : _loginNormal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Iniciar sesión",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text("¿No tienes cuenta? Regístrate"),
              ),

              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("O entra con"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              // Botón Login con Google
              OutlinedButton.icon(
                onPressed: _isLoading || _isGoogleLoading
                    ? null
                    : _loginWithGoogle,
                icon: _isGoogleLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Image.network(
                        "https://cdn-icons-png.flaticon.com/512/2991/2991148.png",
                        height: 24,
                      ), // Icono de Google
                label: const Text(
                  "Continuar con Google",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
