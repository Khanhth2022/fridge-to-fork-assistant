import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

typedef NotificationCallback = Future<void> Function(String? payload);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  NotificationCallback? _onNotificationTapped;

  /// Initialize the notification service
  Future<void> initialize({NotificationCallback? onNotificationTapped}) async {
    _onNotificationTapped = onNotificationTapped;

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android initialization
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    final DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
          defaultPresentAlert: true,
          defaultPresentBadge: true,
          defaultPresentSound: true,
          onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
        );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Request Android permissions (Android 13+)
    // Note: Permissions are automatically handled by flutter_local_notifications
    try {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint(
        'Android permission request not available or already granted: $e',
      );
    }

    // Request iOS permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Send a simple notification
  ///
  /// [id] - Unique notification ID
  /// [title] - Notification title
  /// [body] - Notification body
  /// [payload] - Additional data (e.g., route deeplink or parameters)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'default_channel',
            'Default Channel',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            enableLights: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Send a notification with custom sound
  Future<void> showNotificationWithSound({
    required int id,
    required String title,
    required String body,
    String? payload,
    String soundName = 'notification_sound',
  }) async {
    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'notification_channel',
        'Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        sound: RawResourceAndroidNotificationSound(soundName),
      );

      DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: '$soundName.aiff',
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification with sound: $e');
    }
  }

  /// Test notification function
  /// Use this to test notifications during development
  Future<void> showTestNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Callback when notification is tapped
  void _onNotificationResponse(NotificationResponse response) async {
    debugPrint('Notification triggered: ${response.payload}');
    await _onNotificationTapped?.call(response.payload);
  }

  // iOS callback (for older iOS versions)
  Future<void> _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    debugPrint(
      'iOS notification received: id=$id, title=$title, body=$body, payload=$payload',
    );
    // Handle iOS notification interaction if needed
  }

  /// Get the instance
  static NotificationService get instance => _instance;
}
