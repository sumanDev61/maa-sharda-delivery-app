import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import 'local_notification_service.dart';

class PushService {
  static bool _initialized = false;
  static String? _cachedToken;

  static Future<void> initAndSync() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('PushService: Firebase init skipped ($e)');
      return;
    }

    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {}

    FirebaseMessaging.onMessage.listen((message) async {
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      if (title.isEmpty && body.isEmpty) return;
      await LocalNotificationService().show(
        title: title.isEmpty ? 'Notification' : title,
        body: body,
      );
    });

    try {
      _cachedToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('PushService: getToken failed ($e)');
    }

    if ((_cachedToken ?? '').isNotEmpty) {
      await _syncToken(_cachedToken!);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      _cachedToken = token;
      await _syncToken(token);
    });
  }

  static Future<void> trySyncToken() async {
    if (!_initialized) return;
    if ((_cachedToken ?? '').isEmpty) {
      try {
        _cachedToken = await FirebaseMessaging.instance.getToken();
      } catch (_) {}
    }
    if ((_cachedToken ?? '').isNotEmpty) {
      await _syncToken(_cachedToken!);
    }
  }

  static Future<void> _syncToken(String token) async {
    final platform = kIsWeb
        ? 'fcm'
        : (Platform.isIOS ? 'apn' : 'fcm');
    try {
      await ApiClient().put('/v1/delivery/device-token', body: {
        'device_token': token,
        'device_platform': platform,
      });
    } catch (e) {
      debugPrint('PushService: sync failed ($e)');
    }
  }
}
