import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class DashboardService {
  // 1. OBTENER DATOS DEL USUARIO
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception('unauthorized'); // Forzamos el logout si no hay token
    }

    final response = await ApiClient.get('/db/me');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString(
        'user_data',
        response.body,
      ); // Actualizamos caché local
      return data;
    } else if (response.statusCode == 401) {
      await prefs.clear();
      throw Exception('unauthorized');
    } else {
      throw Exception('server_error');
    }
  }

  // 2. OBTENER PROGRESO DEL DÍA
  static Future<Map<String, dynamic>?> getTodayProgress() async {
    try {
      final response = await ApiClient.get('/ai/intakes/today');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {
      // Si falla, devolvemos null para que la app no crashee y use valores por defecto
    }
    return null;
  }

  // 3. ENVIAR FOTO A LA IA
  static Future<Map<String, dynamic>> analyzeVision(XFile image) async {
    final response = await ApiClient.postMultipart('/ai/vision/analyze', image);
    final responseString = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseString);
    } else {
      try {
        final errorData = jsonDecode(responseString);
        throw Exception(
          errorData['detail'] ?? "Error desconocido al analizar.",
        );
      } catch (_) {
        throw Exception("Error de conexión con la IA.");
      }
    }
  }

  // 4. GUARDAR COMIDA
  static Future<void> saveIntake(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/ai/intakes', body: data);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error del servidor al guardar");
    }
  }
}
