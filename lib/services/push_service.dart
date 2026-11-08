import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';

/// Background/terminated xabar — top-level funksiya SHART (firebase_messaging).
@pragma('vm:entry-point')
Future<void> storePushBgHandler(RemoteMessage message) async {}

/// Mijoz FCM push xizmati. Firebase sozlanmagan bo'lsa (config yo'q)
/// [available]=false bo'lib jimgina o'chiq turadi — ilova normal ishlaydi.
class StorePushService {
  StorePushService._();
  static final StorePushService instance = StorePushService._();

  bool _available = false;
  bool get available => _available;
  String? _token;
  String? _customerCode; // login'da o'rnatiladi

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'store_default',
    'Bildirishnomalar',
    description: 'Buyurtma va qarz bildirishnomalari',
    importance: Importance.high,
  );

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      _available = false;
      debugPrint('StorePush: Firebase sozlanmagan — o\'chiq ($e)');
      return;
    }
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _local.initialize(settings: const InitializationSettings(android: androidInit, iOS: iosInit));
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onBackgroundMessage(storePushBgHandler);
      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        _token = t;
        if (_customerCode != null) _sendToken(t);
      });
      // Mijoz init tugashidan oldin kirgan bo'lsa — token endi yuboriladi.
      if (_customerCode != null) await registerToken();
    } catch (e) {
      debugPrint('StorePush init xato: $e');
    }
  }

  /// Mijoz kirganda chaqiriladi — token backendga (mijoz kodi bilan) yoziladi.
  Future<void> setCustomer(String code) async {
    _customerCode = code;
    await registerToken();
  }

  Future<void> registerToken() async {
    if (!_available || _customerCode == null) return;
    try {
      if (Platform.isIOS) {
        for (var i = 0; i < 5; i++) {
          final apns = await FirebaseMessaging.instance.getAPNSToken();
          if (apns != null) break;
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      final t = await FirebaseMessaging.instance.getToken();
      if (t == null || t.isEmpty) return;
      _token = t;
      await _sendToken(t);
    } catch (e) {
      debugPrint('StorePush registerToken xato: $e');
    }
  }

  /// Chiqishda / hisob o'chirilganda — token'ni backend'da o'chiradi.
  Future<void> logout() async {
    if (_token != null) {
      try {
        await ApiService.unregisterDevice(_token!);
      } catch (_) {}
    }
    _customerCode = null;
    _token = null;
  }

  Future<void> _sendToken(String token) async {
    if (_customerCode == null) return;
    try {
      await ApiService.registerDevice(_customerCode!, token, Platform.isIOS ? 'ios' : 'android');
    } catch (e) {
      debugPrint('StorePush _sendToken xato: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage m) async {
    final n = m.notification;
    if (n == null) return;
    await _local.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: n.android?.smallIcon ?? '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }
}
