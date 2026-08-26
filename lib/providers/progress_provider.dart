// Archivo: lib/providers/progress_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dashboard_service.dart';

class ProgressProvider extends ChangeNotifier {
  bool isLoading = true;
  bool planNeedsRefresh = false;

  double caloriasConsumidas = 0.0;
  // 🌟 NUEVA VARIABLE: Guardará la meta inmutable de HOY
  double caloriasObjetivoHoy = 2000.0;
  Map<String, dynamic> macrosConsumidos = {
    "carbohidratos_g": 0,
    "proteinas_g": 0,
    "grasas_g": 0,
  };
  List<String> historialConsumo = [];
  List<dynamic> turnosPendientes = [];

  Future<void> fetchProgress({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      notifyListeners(); // Avisa a las pantallas que muestren el loading
    }

    try {
      final progreso = await DashboardService.getTodayProgress();
      if (progreso != null) {
        caloriasConsumidas = (progreso['calorias_consumidas'] ?? 0).toDouble();

        // 🌟 EL FIX DEFINITIVO: Leemos el objetivo congelado del Ledger del Backend
        caloriasObjetivoHoy = (progreso['calorias_objetivo_del_dia'] ?? 2000)
            .toDouble();

        macrosConsumidos = progreso['macros_consumidos'] ?? macrosConsumidos;

        if (progreso['historial'] != null) {
          historialConsumo = List<String>.from(progreso['historial']);
        }

        if (progreso['turnos_pendientes'] != null) {
          turnosPendientes = List<dynamic>.from(progreso['turnos_pendientes']);
        } else {
          turnosPendientes = [];
        }
      }
    } catch (e) {
      debugPrint("Error fetching progress in provider: $e");
    } finally {
      isLoading = false;
      notifyListeners(); // 🚀 ¡LA MAGIA! Avisa a todas las pantallas para que se repinten
    }
  }

  void setPlanNeedsRefresh(bool value) {
    planNeedsRefresh = value;
    notifyListeners();
  }

  // Añade estas variables dentro de la clase ProgressProvider:
  bool isLoadingHistory = false;
  int currentStreak = 0;
  int perfectDays = 0;
  List<dynamic> heatMapData = [];

  List<dynamic> weightHistory = [];
  Map<String, dynamic> weightSummary =
      {}; // 🌟 Guardará el peso actual y la diferencia

  Future<void> fetchHistory() async {
    isLoadingHistory = true;
    notifyListeners();

    try {
      // Cargamos ambos a la vez de forma paralela para mayor velocidad
      final results = await Future.wait([
        DashboardService.getHistoryLast30Days(),
        DashboardService.getWeightHistory(),
      ]);

      // 1. Datos del Mapa de Calor
      final data = results[0];
      currentStreak = data['racha_actual'] ?? 0;
      perfectDays = data['dias_perfectos'] ?? 0;
      heatMapData = data['historial'] ?? [];

      // 🌟 2. EL FIX: Datos de la Gráfica de Peso
      final weightResponse = results[1];
      weightSummary =
          weightResponse; // Guardamos el resumen (peso actual, dif. total)
      weightHistory =
          weightResponse['historial'] ??
          []; // Extraemos solo el array para pintar la línea
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  // 🌟 NUEVO: Registrar peso y mantener sincronizado sin romper el día actual
  Future<bool> logWeight(double newWeight) async {
    // 1. Guardamos el peso en la Gráfica
    final success = await DashboardService.logDailyWeight(newWeight);

    if (success) {
      // 2. Recargamos la gráfica para que la línea se mueva
      await fetchHistory();

      // 3. SINCRONIZACIÓN MAESTRA DEL PERFIL
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? cachedData = prefs.getString('user_data');

        if (cachedData != null) {
          final Map<String, dynamic> userData = jsonDecode(cachedData);

          if (userData['peso'] != newWeight) {
            userData['peso'] = newWeight;

            // Enviamos el PUT silencioso para actualizar el perfil base
            await DashboardService.updateUserData(userData);

            // ⚠️ OJO AQUÍ: Ya NO llamamos a setPlanNeedsRefresh(true).
            // Dejamos el menú de HOY intacto. Cuando el usuario abra la app MAÑANA,
            // la IA leerá su nuevo peso (85kg) y generará el nuevo menú con los nuevos macros.

            debugPrint(
              "✅ Perfil base actualizado. Los nuevos macros aplicarán mañana.",
            );
          }
        }
      } catch (e) {
        debugPrint("⚠️ Error sincronizando el perfil base: $e");
      }
    }

    return success;
  }
}
