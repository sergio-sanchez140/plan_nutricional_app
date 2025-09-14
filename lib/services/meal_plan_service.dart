import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/meal.dart';

class MealPlanService {
  final List<String> foodImages;

  MealPlanService(this.foodImages);

  String getRandomImage() => foodImages[Random().nextInt(foodImages.length)];

  Future<Map<String, List<Meal>>> fetchMealPlan(String token) async {
    final url = Uri.parse('http://127.0.0.1:8000/ai/menus?tipo=diario');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) return {};

    final List<dynamic> list = jsonDecode(response.body);
    if (list.isEmpty) return {};

    list.sort((a, b) {
      final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
      final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
      return db.compareTo(da);
    });

    final latest = list.first;
    final menu = (latest['menu'] ?? {}) as Map<String, dynamic>;
    final parsed = <String, List<Meal>>{};

    menu.forEach((type, items) {
      parsed[type] = (items as List)
          .map((item) => Meal.fromJson(item, getRandomImage()))
          .toList();
    });

    return parsed;
  }

  Future<Map<String, List<Meal>>> generateDailyMenu(String token) async {
    final url = Uri.parse('http://127.0.0.1:8000/ai/menus/generate');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'tipo': 'diario'}),
    );

    if (response.statusCode != 200) return {};
    final data = jsonDecode(response.body);
    final menu = (data['menu'] ?? {}) as Map<String, dynamic>;
    final parsed = <String, List<Meal>>{};

    menu.forEach((type, items) {
      parsed[type] = (items as List)
          .map((item) => Meal.fromJson(item, getRandomImage()))
          .toList();
    });

    return parsed;
  }

  Future<Meal> replaceMeal(String token, Meal meal) async {
    final url = Uri.parse(
      'http://127.0.0.1:8000/ai/menus/${meal.planId}/replace-meal/${meal.id}',
    );
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode} al reemplazar comida');
    }

    final data = jsonDecode(response.body);
    return Meal.fromJson(data, getRandomImage());
  }

  Future<Meal> toggleMealCompleted(String token, Meal meal) async {
    final completed = !meal.completed;
    final url = Uri.parse(
      'http://127.0.0.1:8000/ai/meals/${meal.id}/toggle?completed=$completed',
    );
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode} al actualizar comida');
    }

    final data = jsonDecode(response.body);
    return Meal.fromJson(data, meal.image); // mantener la imagen actual
  }
}
