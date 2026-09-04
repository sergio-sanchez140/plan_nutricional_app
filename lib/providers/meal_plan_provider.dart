import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../services/meal_plan_service.dart';
import '../errors/profile_incomplete_exception.dart';

class MealPlanProvider extends ChangeNotifier {
  bool isLoading = true;
  bool isReplacingMeal = false;
  Map<String, List<Meal>> meals = {};

  // Guardamos un error si lo hay para mostrarlo en la UI
  String? errorMessage;
  ProfileIncompleteException? profileError;

  late final MealPlanService _service;

  MealPlanProvider() {
    final List<String> foodImages = [
      "assets/images/foods/avena-frutos-rojos.png",
      "assets/images/foods/pollo-quinoa.png",
      "assets/images/foods/salmon-vegetables.png",
      "assets/images/foods/yogurt-nueces.png",
    ];
    _service = MealPlanService(foodImages);
  }

  Future<void> fetchMealPlan({bool isSilent = false}) async {
    if (!isSilent) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      meals = await _service.fetchMealPlan();
    } catch (e) {
      errorMessage = 'Error al cargar el plan: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateDailyMenu() async {
    isLoading = true;
    isReplacingMeal = true;
    errorMessage = null;
    profileError = null;
    notifyListeners();

    try {
      meals = await _service.generateDailyMenu();
    } on ProfileIncompleteException catch (e) {
      profileError = e;
    } catch (e) {
      errorMessage = 'Error al generar el menú: $e';
    } finally {
      isLoading = false;
      isReplacingMeal = false;
      notifyListeners();
    }
  }

  Future<void> replaceMeal(String type, Meal meal) async {
    isReplacingMeal = true;
    errorMessage = null;
    notifyListeners();

    try {
      final newMeal = await _service.replaceMeal(meal);
      final index = meals[type]?.indexWhere((m) => m.id == meal.id);
      if (index != null && index != -1) {
        meals[type]![index] = newMeal;
      }
    } catch (e) {
      errorMessage = 'Error al reemplazar: $e';
    } finally {
      isReplacingMeal = false;
      notifyListeners();
    }
  }

  Future<void> toggleMealCompleted(String type, Meal meal) async {
    try {
      final updated = await _service.toggleMealCompleted(meal);
      final index = meals[type]?.indexWhere((m) => m.id == meal.id);
      if (index != null && index != -1) {
        meals[type]![index] = updated;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Error al actualizar: $e';
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    profileError = null;
    notifyListeners();
  }
}
