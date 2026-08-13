import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _loading = false;

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError("Completa todos los campos");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Las contraseñas no coinciden");
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final url = Uri.parse('http://127.0.0.1:8000/db/users');

      final body = jsonEncode({
        "nombre": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
      });

      // Cambiamos el http.post por ApiClient
      final response = await ApiClient.post('/db/users', body: {
        "nombre": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
      });

      print("REGISTER STATUS: ${response.statusCode}");
      print("REGISTER BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();

        final token = data['access_token'];
        final user = data['user'];

        if (token != null) {
          await prefs.setString('access_token', token);
        }

        if (user != null) {
          await prefs.setString('user_id', user['id'].toString());
          await prefs.setString('user_name', user['nombre']);
          await prefs.setString('user_email', user['email']);
        }

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/registerData');
      } else {
        String msg = "Error al registrarse";

        try {
          final error = jsonDecode(response.body);

          if (error is Map<String, dynamic>) {
            msg = error['detail'] ?? error['message'] ?? msg;
          }
        } catch (_) {}

        _showError(msg);
      }
    } catch (e) {
      print("ERROR REGISTER: $e");

      _showError("Error de conexión con el servidor");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nameController.dispose();

    _emailController.dispose();

    _passwordController.dispose();

    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              const SizedBox(height: 30),

              const Text(
                "Crear cuenta",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              const Text(
                "Empieza tu transformación hoy",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // NOMBRE
              TextField(
                controller: _nameController,

                decoration: InputDecoration(
                  hintText: "Nombre completo",

                  prefixIcon: const Icon(Icons.person_outline),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              const SizedBox(height: 20),

              // EMAIL
              TextField(
                controller: _emailController,

                decoration: InputDecoration(
                  hintText: "Correo electrónico",

                  prefixIcon: const Icon(Icons.email_outlined),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              const SizedBox(height: 20),

              // PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: true,

                decoration: InputDecoration(
                  hintText: "Contraseña",

                  prefixIcon: const Icon(Icons.lock_outline),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              const SizedBox(height: 20),

              // CONFIRM PASSWORD
              TextField(
                controller: _confirmPasswordController,

                obscureText: true,

                decoration: InputDecoration(
                  hintText: "Confirmar contraseña",

                  prefixIcon: const Icon(Icons.lock_outline),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _loading ? null : _register,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade700,

                  padding: const EdgeInsets.symmetric(vertical: 16),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Crear cuenta",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
