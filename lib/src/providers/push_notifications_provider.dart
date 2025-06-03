// lib/src/providers/push_notifications_provider.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Modelo simple (solo título y body) para la notificación.
class NotificationItem {
  final String title;
  final String body;

  NotificationItem({
    required this.title,
    required this.body,
  });

  /// Convierte el objeto NotificationItem a un Map<String, dynamic>
  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
      };

  /// Crea un NotificationItem a partir de un Map<String, dynamic>
  factory NotificationItem.fromMap(Map<String, dynamic> map) =>
      NotificationItem(
        title: map['title'] ?? '',
        body: map['body'] ?? '',
      );
}

/// Handler para mensajes en background o cuando la app está cerrada.
/// Aquí guardamos en SharedPreferences y mostramos también la notificación local.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Mensaje en background: ${message.messageId}');

  // 1) Guardar en SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('notifications_list');
  List<dynamic> notificationsList =
      jsonString != null ? json.decode(jsonString) as List<dynamic> : [];

  final title = message.notification?.title ?? 'Sin título';
  final body = message.notification?.body ?? 'Sin mensaje';

  notificationsList.add({'title': title, 'body': body});
  await prefs.setString('notifications_list', json.encode(notificationsList));
  print('Notificación guardada en background');

  // 2) Mostrar notificación local en background
  final localPlugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('notification_icon');
  await localPlugin.initialize(
    InitializationSettings(android: androidInit),
  );

  const androidDetails = AndroidNotificationDetails(
    'idsonido',                         // Canal personalizado
    'canalnuevo',                       
    channelDescription: 'canal personalizado para las notificaciones',
    importance: Importance.max,
    priority: Priority.high,
    icon: 'notification_icon',          // Icono personalizado
    sound: RawResourceAndroidNotificationSound('pruebasonido'),
    playSound: true,
  );

  await localPlugin.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(android: androidDetails),
  );
}

class PushNotificationsProvider {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin;

  void Function(NotificationItem)? onForegroundNotificationReceived;

  PushNotificationsProvider({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotificationsPlugin,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotificationsPlugin =
            localNotificationsPlugin ?? FlutterLocalNotificationsPlugin();

  /// Inicializa Firebase Messaging y las notificaciones locales.
  Future<void> initialize() async {
    try {
      // 1. Registra handler de background.
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);

      // 2. Inicializa plugin de notificaciones locales con icono.
      const androidInit = AndroidInitializationSettings('notification_icon');
      const initSettings = InitializationSettings(
        android: androidInit,
      );
      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (resp) async {
          await _onSelectNotification(resp.payload);
        },
      );

      // 3. Crea el canal personalizado (Android 8+).
      const channel = AndroidNotificationChannel(
        'idsonido',                         // mismo ID usado en AndroidNotificationDetails
        'canalnuevo',                       // nombre visible
        description: 'canal personalizado para las notificaciones',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('pruebasonido'),
        playSound: true,
        // no es necesario especificar ícono aquí, el canal hereda del manifest
      );
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 4. Solicita permisos en iOS.
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('Permiso de notificaciones (iOS): ${settings.authorizationStatus}');

      // 5. Maneja mensajes en primer plano.
      FirebaseMessaging.onMessage.listen((msg) async {
        print('Mensaje (primer plano): ${msg.messageId}');
        if (msg.notification != null) {
          final title = msg.notification!.title ?? 'Sin título';
          final body = msg.notification!.body ?? 'Sin mensaje';
          final newItem = NotificationItem(title: title, body: body);

          if (onForegroundNotificationReceived != null) {
            onForegroundNotificationReceived!(newItem);
          }

          await _showLocalNotification(
            title: title,
            body: body,
            notificationId: msg.hashCode,
          );
        }
      });

      // 6. Notificación al abrir la app desde una notificación.
      FirebaseMessaging.onMessageOpenedApp.listen((msg) {
        print('Notificación tocada (abriendo app): ${msg.messageId}');
      });

      // 7. Obtiene token FCM.
      final token = await _messaging.getToken();
      print('Token FCM: $token');
    } catch (e) {
      print('Error al inicializar notificaciones push: $e');
    }
  }

  Future<void> _onSelectNotification(String? payload) async {
    print('Notificación seleccionada con payload: $payload');
    // Navegación o acción adicional aquí.
  }

  /// Muestra una notificación local sencilla (solo texto).
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    int notificationId = 0,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'idsonido',
        'canalnuevo',
        channelDescription: 'canal personalizado para las notificaciones',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'notification_icon',        // Icono personalizado
        sound: RawResourceAndroidNotificationSound('pruebasonido'),
        playSound: true,
      );
      final notificationDetails =
          NotificationDetails(android: androidDetails);

      await _localNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
      );
    } catch (error) {
      print('Error al mostrar la notificación local: $error');
    }
  }
}

