import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notif = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _notif.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
    );
  }

  Future<void> showSimpleNotification(int id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'finora_channel',
      'Finora Notifications',
      channelDescription: 'Finora reminders and alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _notif.show(id, title, body, NotificationDetails(android: androidDetails, iOS: iosDetails));
  }
}
