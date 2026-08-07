import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  const LocalNotificationService._();

  static const String channelId = 'pick_my_snacks_updates';
  static const String channelName = 'Pick My Snacks updates';
  static const String _channelDescription =
      'Order, kitchen, and stock updates from Pick My Snacks';
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        channelId,
        channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static Future<void>? _initialization;
  static StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }
    if (_initialization != null) {
      return _initialization;
    }
    final initialization = _initializePlugin();
    _initialization = initialization;
    try {
      await initialization;
      _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen(
        (message) => unawaited(showRemoteMessage(message)),
      );
      _initialized = true;
    } finally {
      _initialization = null;
    }
  }

  static Future<void> _initializePlugin() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_steps'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(_androidChannel);
      final notificationsEnabled =
          await androidPlugin?.areNotificationsEnabled() ?? false;
      if (!notificationsEnabled) {
        await androidPlugin?.requestNotificationsPermission();
      }
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> showRemoteMessage(
    RemoteMessage message, {
    bool dataOnly = false,
  }) async {
    if (kIsWeb || (dataOnly && message.notification != null)) {
      return;
    }
    final title =
        message.notification?.title?.trim() ??
        message.data['title']?.toString().trim();
    final body =
        message.notification?.body?.trim() ??
        message.data['body']?.toString().trim() ??
        message.data['message']?.toString().trim();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    await initialize();
    await _plugin.show(
      _notificationId(message),
      title?.isNotEmpty == true ? title : 'Pick My Snacks',
      body?.isNotEmpty == true ? body : 'You have a new order update.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_steps',
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  static int _notificationId(RemoteMessage message) {
    final stableValue =
        message.messageId ??
        message.sentTime?.millisecondsSinceEpoch.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString();
    return stableValue.hashCode & 0x7fffffff;
  }
}
