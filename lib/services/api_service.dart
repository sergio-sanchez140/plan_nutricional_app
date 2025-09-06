import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://TU_BACKEND_URL"; // cambia por el host real

  // --- Health Check ---
  static Future<bool> healthCheck() async {
    final response = await http.get(Uri.parse("$baseUrl/health"));
    return response.statusCode == 200;
  }

  // --- Nutrición ---
  static Future<Map<String, dynamic>> getDailyPlan(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/nutrition/plan-nutricional-daily"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener plan diario: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> getWeeklyPlan(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/nutrition/plan-nutricional-weekly"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener plan semanal: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> getMonthlyPlan(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/nutrition/plan-nutricional-monthly"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener plan mensual: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> getSnacks(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/nutrition/snacks-dailys"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener snacks: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> getSubstitutions() async {
    final response = await http.get(Uri.parse("$baseUrl/nutrition/substitutions"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener sustituciones: ${response.body}");
    }
  }

  // --- Users ---
  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse("$baseUrl/db/users"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al listar usuarios: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/db/users"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al crear usuario: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> updateUser(String email, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/db/users/$email"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al actualizar usuario: ${response.body}");
    }
  }

  // --- Plans ---
  static Future<Map<String, dynamic>> savePlan(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/db/plans"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al guardar plan: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> getUserPlans(String userId) async {
    final response = await http.get(Uri.parse("$baseUrl/db/plans/$userId"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener planes del usuario: ${response.body}");
    }
  }
}