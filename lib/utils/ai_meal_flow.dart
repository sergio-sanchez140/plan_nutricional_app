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
import '../widgets/free_intake_sheet.dart';

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

  // ========================================================================
  // INICIA EL FLUJO MANUAL (TEXTO)
  // ========================================================================
  static Future<void> startManualFlow(BuildContext mainContext) async {
    // 🌟 FÍJATE AQUÍ: Renombramos la variable de entrada a 'mainContext'

    showModalBottomSheet(
      context: mainContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // 🌟 FÍJATE AQUÍ: Al contexto del modal le llamamos 'sheetContext'
      // para no mezclarlo con el mainContext que sobrevive
      builder: (sheetContext) => FreeIntakeSheet(
        onSuccess: (data) async {
          // 🛡️ Verificamos que el Dashboard siga vivo
          if (!mainContext.mounted) return;

          // 🌟 USAMOS EL MAIN CONTEXT PARA TODO A PARTIR DE AHORA
          final turnosPendientes = mainContext
              .read<ProgressProvider>()
              .turnosPendientes;

          final result = await AiResultBottomSheet.show(
            context: mainContext, // Usamos mainContext
            data: data,
            intentosRestantes: 0,
            turnosPendientes: turnosPendientes,
          );

          if (result != null && result['action'] == 'confirm') {
            if (!mainContext.mounted) return;
            // 🌟 USAMOS EL MAIN CONTEXT PARA GUARDAR Y MOSTRAR EL LOADING FINAL
            await guardarPlatoAnalizado(
              mainContext,
              data,
              result['resoluciones'],
            );
          }
        },
      ),
    );
  }

  // 2. ENVÍA LA FOTO Y MUESTRA RESULTADOS
  static Future<void> _sendPhotoToBackend(
    BuildContext context,
    XFile image,
    int intentos,
  ) async {
    // 🌟 LLAMADA AL NUEVO LOADING (Textos de escáner)
    LoadingAiDialog.show(
      context,
      title: "Analizando tu plato",
      texts: [
        "Identificando ingredientes...",
        "Estimando tamaños de porción...",
        "Calculando calorías y macros...",
        "¡Ya casi lo tenemos!",
      ],
    );

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

  // 3. GUARDA EL PLATO (Versión Blindada)
  static Future<void> guardarPlatoAnalizado(
    BuildContext context,
    Map<String, dynamic> data,
    dynamic resolucionesMap,
  ) async {
    LoadingAiDialog.show(
      context,
      title: "Registrando comida",
      texts: [
        "Guardando los datos nutricionales...",
        "Actualizando tu historial de hoy...",
        "Recalculando tu tanque de energía...",
        "Ajustando el resto de tu plan...",
      ],
    );

    try {
      List<Map<String, String>> listaResoluciones = [];

      // 🌟 EL TANQUE BLINDADO: Inspeccionamos la variable sin dar nada por hecho
      if (resolucionesMap != null) {
        // 1. Si es un Mapa (Viene de la cámara generalmente)
        if (resolucionesMap is Map) {
          resolucionesMap.forEach((key, value) {
            listaResoluciones.add({
              "turno": key.toString(),
              "estado": value.toString(),
            });
          });
        }
        // 2. Si es una Lista de objetos (Viene del modo manual generalmente)
        else if (resolucionesMap is Iterable) {
          for (var item in resolucionesMap) {
            if (item is Map) {
              listaResoluciones.add({
                "turno": item["turno"]?.toString() ?? "",
                "estado": item["estado"]?.toString() ?? "",
              });
            } else if (item is String) {
              // ⚠️ ESTE ERA EL PROBLEMA: Si el modal solo devuelve una lista de strings (ej: ["desayuno", "merienda"])
              listaResoluciones.add({
                "turno": item,
                "estado": "completado", // Asumimos completado por defecto
              });
            }
          }
        }
      }

      await DashboardService.saveIntake(
        data,
        resolucionPendientes: listaResoluciones,
      );

      if (!context.mounted) return;

      await context.read<ProgressProvider>().fetchProgress(silent: true);
      context.read<ProgressProvider>().setPlanNeedsRefresh(true);

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
        LoadingAiDialog.hide(context);
        // Mensaje limpio, sin emojis para proteger Flutter Web
        _showMessage(context, '¡Plan recalculado con éxito!');
      }
    } catch (e) {
      if (context.mounted) {
        LoadingAiDialog.hide(context);
        // Añadimos imprimir el error real en consola para depurar si vuelve a fallar
        print("❌ Error en guardarPlatoAnalizado: $e");
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
