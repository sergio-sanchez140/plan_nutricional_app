// Archivo: lib/providers/progress_provider.dart
import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class ProgressProvider extends ChangeNotifier {
  bool isLoading = true;

  bool planNeedsRefresh = false;

  double caloriasConsumidas = 0.0;
  Map<String, dynamic> macrosConsumidos = {
    "carbohidratos_g": 0,
    "proteinas_g": 0,
    "grasas_g": 0,
  };
  List<String> historialConsumo = [];
  List<dynamic> turnosPendientes = [];

  // Método que recarga los datos y avisa a toda la app
  Future<void> fetchProgress({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      notifyListeners(); // Avisa a las pantallas que muestren el loading
    }

    try {
      final progreso = await DashboardService.getTodayProgress();
      if (progreso != null) {
        caloriasConsumidas = (progreso['calorias_consumidas'] ?? 0).toDouble();
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
}
