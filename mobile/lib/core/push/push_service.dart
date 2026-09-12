import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_navigator.dart';

const _channelId = 'iias_push';
const _channelName = 'IIAS alerts';

const _tabRoutes = {
  '/dashboard',
  '/members',
  '/collection',
  '/events',
  '/more',
  '/member-home',
};

const _allowedRoutes = {
  ..._tabRoutes,
  '/notifications',
  '/payment-approvals',
  '/join-requests',
  '/meetings',
  '/open-meeting',
};

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class PushService {
  PushService._();

  static final PushService instance = PushService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _pendingRoute;
  String? token;
  void Function(String token)? onTokenRefresh;

  bool get isReady => _ready;

  String get platform =>
      !kIsWeb && Platform.isIOS ? 'ios' : 'android';

  Future<void> initialize() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    try {
      await Firebase.initializeApp();
    } catch (_) {
      debugPrint(
        'Firebase not configured (add android/app/google-services.json to enable push).',
      );
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        _openFromPayload(response.payload);
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Payments, join requests and donations',
            importance: Importance.high,
          ),
        );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      openRoute(message.data['route']);
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _pendingRoute = _sanitizeRoute(initial.data['route']);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((value) {
      token = value;
      onTokenRefresh?.call(value);
    });

    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM token failed: $e');
    }

    _ready = true;
  }

  void flushPending() {
    final route = _pendingRoute;
    if (route == null) return;
    _pendingRoute = null;
    openRoute(route);
  }

  void openRoute(String? route) {
    final path = _sanitizeRoute(route);
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) {
      _pendingRoute = path;
      return;
    }
    final router = GoRouter.of(ctx);
    if (_tabRoutes.contains(path)) {
      router.go(path);
    } else {
      router.push(path);
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'IIAS';
    final body = notification?.body ?? '';
    await _local.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Payments, join requests and donations',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode({'route': message.data['route'] ?? '/notifications'}),
    );
  }

  void _openFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      openRoute('/notifications');
      return;
    }
    try {
      final data = jsonDecode(payload);
      if (data is Map && data['route'] is String) {
        openRoute(data['route'] as String);
        return;
      }
    } catch (_) {}
    openRoute(payload);
  }

  String _sanitizeRoute(String? route) {
    if (route == null || route.isEmpty) return '/notifications';
    if (_allowedRoutes.contains(route)) return route;
    if (RegExp(r'^/meetings/[A-Za-z0-9-]+$').hasMatch(route)) return route;
    return '/notifications';
  }
}
