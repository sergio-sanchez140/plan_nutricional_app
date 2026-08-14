import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ApiClient {
  // Si usas emulador Android:
  static const String baseUrl = 'http://127.0.0.1:8000';
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers();
    return await http.get(url, headers: headers);
  }

  static Future<http.Response> post(String endpoint, {Object? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers();

    return await http.post(url, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> patch(String endpoint, {Object? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers();

    return await http.patch(url, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> put(String endpoint, {Object? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers();
    return await http.put(url, headers: headers, body: jsonEncode(body));
  }

  static Future<http.StreamedResponse> postMultipart(String endpoint, XFile file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // 🔥 LA MAGIA PARA QUE FUNCIONE EN WEB Y MÓVIL
    final bytes = await file.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: file.name)
    );

    return await request.send();
  }
}
