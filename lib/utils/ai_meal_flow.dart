// Archivo: lib/utils/ai_meal_flow.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Basado exactamente en tus imports de dashboard.dart
import '../services/dashboard_service.dart';
import '../services/notification_service.dart';
import '../providers/progress_provider.dart';

import '../widgets/modals/photo_confirmation_dialog.dart';
import '../widgets/modals/loading_ai_dialog.dart';
import '../widgets/modals/ai_result_bottom_sheet.dart';
import '../widgets/modals/recalculating_dialog.dart';

class AiMealFlow {
  // 1. INICIA EL FLUJO DE LA CÁMARA
  static Future<void> startCameraFlow(
    BuildContext context, {
    int intentosRestantes = 3,
  }) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final imageBytes = await image.readAsBytes();
    if (!context.mounted) return;

    final bool? confirmado = await PhotoConfirmationDialog.show(
      context,
      imageBytes,
    );

    if (confirmado == true) {
      await _sendPhotoToBackend(context, image, intentosRestantes);
    } else if (confirmado == false) {
      // Reintento: volvemos a abrir la cámara
      await startCameraFlow(context, intentosRestantes: intentosRestantes);
    }
  }

  // 2. ENVÍA LA FOTO Y MUESTRA RESULTADOS
  static Future<void> _sendPhotoToBackend(
    BuildContext context,
    XFile image,
    int intentos,
  ) async {
    LoadingAiDialog.show(context);
    try {
      final data = await DashboardService.analyzeVision(image);
      if (!context.mounted) return;

      LoadingAiDialog.hide(context);

      final turnosPendientes = context
          .read<ProgressProvider>()
          .turnosPendientes;

      final result = await AiResultBottomSheet.show(
        context: context,
        data: data,
        intentosRestantes: intentos - 1,
        turnosPendientes: turnosPendientes,
      );

      if (result != null) {
        if (result['action'] == 'confirm') {
          await guardarPlatoAnalizado(context, data, result['resoluciones']);
        } else if (result['action'] == 'retry' && intentos > 1) {
          await startCameraFlow(context, intentosRestantes: intentos - 1);
        }
      }
    } catch (e) {
      if (context.mounted) {
        LoadingAiDialog.hide(context);
        _showMessage(
          context,
          'Ups: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true,
        );
      }
    }
  }

  // 3. GUARDA EL PLATO (Público para que pueda ser llamado también desde el modo Manual)
  static Future<void> guardarPlatoAnalizado(
    BuildContext context,
    Map<String, dynamic> data,
    dynamic resolucionesMap,
  ) async {
    RecalculatingDialog.show(context);

    try {
      List<Map<String, String>> listaResoluciones = [];
      if (resolucionesMap != null) {
        final map = resolucionesMap as Map<String, String>;
        listaResoluciones = map.entries
            .map((e) => {"turno": e.key, "estado": e.value})
            .toList();
      }

      await DashboardService.saveIntake(
        data,
        resolucionPendientes: listaResoluciones,
      );

      if (!context.mounted) return;

      await context.read<ProgressProvider>().fetchProgress(silent: true);
      context.read<ProgressProvider>().setPlanNeedsRefresh(true);

      // Cancelación de notificaciones
      for (var resolucion in listaResoluciones) {
        if (resolucion['estado'] == 'completado' ||
            resolucion['estado'] == 'sustituido') {
          final String turnoCompletado = resolucion['turno'] ?? '';
          await NotificationService().cancelByReference(
            "meal_$turnoCompletado",
          );
        }
      }

      if (context.mounted) {
        RecalculatingDialog.hide(context);
        _showMessage(context, '¡Plan recalculado con éxito! 🚀');
      }
    } catch (e) {
      if (context.mounted) {
        RecalculatingDialog.hide(context);
        _showMessage(context, 'No se pudo guardar la comida', isError: true);
      }
    }
  }

  // 4. SNACKBAR HELPER
  static void _showMessage(
    BuildContext context,
    String msg, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
