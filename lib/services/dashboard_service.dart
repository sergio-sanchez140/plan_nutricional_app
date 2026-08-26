import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart'; // Añade esto para debugPrint

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

  // 4. GUARDAR COMIDA (Con Resolución de Pendientes)
  static Future<void> saveIntake(
    Map<String, dynamic> originalData, {
    List<Map<String, String>>? resolucionPendientes,
  }) async {
    final Map<String, dynamic> data = jsonDecode(jsonEncode(originalData));

    // 🩹 Mapeo defensivo de macros
    if (data['macros'] != null) {
      final macros = data['macros'];
      macros['proteinas_g'] = macros['proteinas'] ?? macros['proteinas_g'] ?? 0;
      macros['carbohidratos_g'] =
          macros['carbohidratos'] ?? macros['carbohidratos_g'] ?? 0;
      macros['grasas_g'] = macros['grasas'] ?? macros['grasas_g'] ?? 0;
      data['macros'] = macros;
    }

    // 🚀 Inyectamos el array de resoluciones si existe
    if (resolucionPendientes != null && resolucionPendientes.isNotEmpty) {
      data['resolucion_pendientes'] = resolucionPendientes;
    }

    final response = await ApiClient.post('/ai/intakes', body: data);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error del servidor al guardar la ingesta");
    }
  }

  // 5. ANALIZAR TEXTO MANUAL (No guarda, solo analiza)
  static Future<Map<String, dynamic>> analyzeText(String texto) async {
    final response = await ApiClient.post(
      '/ai/text/analyze',
      body: {'texto': texto},
    );

    // Asumimos que ApiClient maneja el jsonEncode internamente,
    // si no, asegúrate de que el body se envíe como JSON.
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? "Error al analizar el texto.");
      } catch (_) {
        throw Exception("Error de conexión con la IA.");
      }
    }
  }

  // 6. OBTENER HISTORIAL DE CONSTANCIA (30 DÍAS)
  static Future<Map<String, dynamic>> getHistoryLast30Days() async {
    final response = await ApiClient.get('/ai/progress/history/last-30-days');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener el historial: ${response.statusCode}');
    }
  }

  // 7. OBTENER DETALLE DE UN DÍA ESPECÍFICO (Modo Lectura)
  static Future<Map<String, dynamic>> getDailyHistoryDetail(String date) async {
    final response = await ApiClient.get('/ai/progress/history/$date');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Error al obtener el detalle del día: ${response.statusCode}',
      );
    }
  }

  // 8. ACTUALIZAR PERFIL DEL USUARIO
  static Future<void> updateUserData(Map<String, dynamic> data) async {
    // 1. Extraemos el email de los datos que nos pasa la UI
    final email = data['email'];

    if (email == null || email.isEmpty) {
      throw Exception('Error: Falta el email para actualizar el usuario');
    }

    // 2. 🚀 AHORA SÍ: Construimos la ruta dinámica correcta
    final response = await ApiClient.put('/db/users/$email', body: data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Actualizamos la caché local para que la app sea súper rápida
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', response.body);
    } else {
      throw Exception('Error al actualizar el perfil: ${response.statusCode}');
    }
  }

  // 9. OBTENER HISTORIAL DE PESO
  static Future<Map<String, dynamic>> getWeightHistory() async {
    // 🌟 Cambiamos a Map
    try {
      final response = await ApiClient.get(
        '/ai/progress/weight',
      ); // Pon tu ruta real aquí
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Devuelve el objeto completo
      }
      return {};
    } catch (e) {
      debugPrint("Error obteniendo historial de peso: $e");
      return {};
    }
  }

  // 10. REGISTRAR PESO DIARIO
  static Future<bool> logDailyWeight(double weight, {String? date}) async {
    try {
      final payload = <String, dynamic>{"peso": weight};
      if (date != null) payload["fecha"] = date;

      // Usamos POST como indica tu API
      final response = await ApiClient.post('/ai/progress/weight', body: payload);
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error registrando peso: $e");
      return false;
    }
  }
}
