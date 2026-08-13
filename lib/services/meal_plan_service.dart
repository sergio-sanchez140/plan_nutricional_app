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

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return _parseMenuResponse(decoded);
    } else if (response.statusCode == 400 || response.statusCode == 422) {
      final errorData = jsonDecode(response.body);
      throw ProfileIncompleteException(
        message: errorData['detail'] ?? "Perfil incompleto",
        missingFields: List<String>.from(errorData['missing_fields'] ?? []),
      );
    } else {
      throw Exception("Error al obtener el plan (${response.statusCode})");
    }
  }

  Map<String, List<Meal>> _parseMenuResponse(dynamic rawData) {
    Map<String, List<Meal>> resultMap = {};

    if (rawData is! List || rawData.isEmpty) {
      return resultMap;
    }

    // Tomamos el último o primer plan disponible
    final planObj = rawData.first as Map<String, dynamic>;
    final menuObj = planObj['menu'] as Map<String, dynamic>?;

    if (menuObj == null) return resultMap;

    // Recorremos los días (ej: "1")
    menuObj.forEach((diaKey, turnosMap) {
      if (turnosMap is Map<String, dynamic>) {
        // Recorremos cada turno ("desayuno", "comida", "cena", etc.)
        turnosMap.forEach((turnoKey, comidasList) {
          if (comidasList is List) {
            for (var item in comidasList) {
              if (item is Map<String, dynamic>) {
                final meal = Meal.fromJson(item, getRandomImage());
                
                // Agrupamos en el mapa por el nombre del turno
                if (!resultMap.containsKey(turnoKey)) {
                  resultMap[turnoKey] = [];
                }
                resultMap[turnoKey]!.add(meal);
              }
            }
          }
        });
      }
    });

    return resultMap;
  }

  Future<Map<String, List<Meal>>> generateDailyMenu() async {
    final response = await ApiClient.post(
      '/ai/menus/generate',
      body: {'tipo': 'diario'},
    );

    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respuesta inválida del servidor');
    }

    // 🔥 MANEJO DE ERROR REAL
    if (response.statusCode != 200) {
      final detail = data is Map ? data['detail'] : null;

      if (detail is Map && detail['code'] == 'PROFILE_INCOMPLETE') {
        throw ProfileIncompleteException(
          message: detail['message'],
          missingFields: List<String>.from(detail['missing_fields'] ?? []),
        );
      }

      final msg = (detail is Map)
          ? detail['message']
          : (data is Map ? data['message'] : null);

      throw Exception(msg ?? 'Error al generar menú');
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
