import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // 🌟 Detecta si estamos en Chrome

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) {
      debugPrint("🌐 MODO WEB DETECTADO: Notificaciones locales desactivadas.");
      return;
    }
    // 1. Inicializar zonas horarias
    tz.initializeTimeZones();
    // Opcional: Establecer la zona local (depende del dispositivo)
    // tz.setLocalLocation(tz.getLocation('Europe/Madrid'));

    // 2. Configuración Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. Configuración iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // 4. Unir configuraciones
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings, // ✅ Añadimos "settings:"
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
          "Usuario tocó la notificación con payload: ${response.payload}",
        );
      },
    );
  }

  // Método para pedir permisos explícitos (Android 13+ y iOS)
  Future<void> requestPermissions() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();
  }

  // Método base para cancelar una (cuando el usuario come)
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id); // ✅ Añadido id:
    debugPrint("🔔 Notificación $id cancelada exitosamente.");
  }

  // 🚀 LA MAGIA: Coge el JSON del Backend y programa las alarmas
  Future<void> scheduleFromBackend(List<dynamic> notificacionesJson) async {
    if (kIsWeb) return; // 🛡️ Salimos sin hacer nada en Chrome
    // 1. Configuramos el canal (Obligatorio en Android 8+)
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'ai_retention_channel', // ID interno
          'Recordatorios de Comidas', // Nombre que ve el usuario en Ajustes
          channelDescription: 'Avisos inteligentes para tus comidas y rachas',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // 2. Iteramos por cada notificación que ha enviado la IA
    for (var noti in notificacionesJson) {
      final int id = noti['id_notificacion'];
      final String title = noti['titulo'];
      final String body = noti['cuerpo'];
      final String horaString = noti['hora_programada'];
      final String referencia = noti['id_referencia']; // Ej: "meal_47"

      // 3. Convertimos el String del backend ("2026-08-29T20:30:00") a Fecha local
      final DateTime parsedDate = DateTime.parse(horaString);

      // AQUÍ USAMOS tz.TZDateTime (¡Adiós warning del linter!)
      // Esto asegura que la alarma suene a las 20:30 de la hora local del usuario
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        parsedDate,
        tz.local,
      );

      // Regla de oro: No podemos programar viajes al pasado
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint(
          "⚠️ Ignorando notificación '$title' porque su hora ya pasó.",
        );
        continue;
      }

      // 4. Programamos en el Sistema Operativo
      // 4. Programamos en el Sistema Operativo
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: referencia,
      );

      debugPrint("⏰ Programada con éxito: '$title' para el $scheduledDate");
    }
  }

  // 🌟 Busca entre las notificaciones pendientes y cancela la que coincida
  Future<void> cancelByReference(String referenceId) async {
    if (kIsWeb) return; // 🛡️ Salimos sin hacer nada en Chrome
    final pendingNotifications = await flutterLocalNotificationsPlugin
        .pendingNotificationRequests();

    for (var request in pendingNotifications) {
      if (request.payload == referenceId) {
        await cancelNotification(request.id);
        debugPrint("🚫 Alarma interceptada y cancelada para: $referenceId");
      }
    }
  }
}
