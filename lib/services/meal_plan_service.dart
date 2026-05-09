import 'dart:convert';
import 'dart:math';
import 'package:plan_nutricional_app/errors/profile_incomplete_exception.dart';
import 'package:plan_nutricional_app/services/api_client.dart';
import '../models/meal.dart';

class MealPlanService {
  final List<String> foodImages;

  MealPlanService(this.foodImages);

  String getRandomImage() => foodImages[Random().nextInt(foodImages.length)];

  Future<Map<String, List<Meal>>> fetchMealPlan() async {
    final response = await ApiClient.get('/ai/menus?tipo=diario');

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

  Future<Map<String, List<Meal>>> generateDailyMenu() async {
    final response = await ApiClient.post(
      '/ai/menus/generate',
      body: {'tipo': 'diario'},
    );

    final data = jsonDecode(response.body);

    // 🔥 MANEJO DE ERROR REAL
    if (response.statusCode != 200) {
      final detail = data['detail'];

      if (detail != null && detail['code'] == 'PROFILE_INCOMPLETE') {
        throw ProfileIncompleteException(
          message: detail['message'],
          missingFields: List<String>.from(detail['missing_fields'] ?? []),
        );
      }

      throw Exception(detail?['message'] ?? 'Error al generar menú');
    }

    final menu = (data['menu'] ?? {}) as Map<String, dynamic>;

    final parsed = <String, List<Meal>>{};

    menu.forEach((type, items) {
      parsed[type] = (items as List)
          .map((item) => Meal.fromJson(item, getRandomImage()))
          .toList();
    });

    return parsed;
  }

  Future<Meal> replaceMeal(Meal meal) async {
    final response = await ApiClient.post(
      '/ai/menus/${meal.planId}/replace-meal/${meal.id}',
    );

    if (response.statusCode != 200) {
      throw Exception('Error al reemplazar comida');
    }

    final data = jsonDecode(response.body);
    return Meal.fromJson(data, getRandomImage());
  }

  Future<Meal> toggleMealCompleted(Meal meal) async {
    final completed = !meal.completed;

    final response = await ApiClient.patch(
      '/ai/meals/${meal.id}/toggle?completed=$completed',
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar comida');
    }

    final data = jsonDecode(response.body);

    return Meal.fromJson(data, meal.image);
  }
}
