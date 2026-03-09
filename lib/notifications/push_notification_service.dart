import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../auth/auth_session_manager.dart';
import '../constants/firebase_constants.dart';

const AndroidNotificationChannel _chatNotificationChannel =
    AndroidNotificationChannel(
      'chat_messages_channel',
      'Chat Messages',
      description: 'Notifications for incoming chat messages',
      importance: Importance.high,
    );

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: FirebaseConfig.apiKey,
      authDomain: FirebaseConfig.authDomain,
      projectId: FirebaseConfig.projectId,
      storageBucket: FirebaseConfig.storageBucket,
      messagingSenderId: FirebaseConfig.messagingSenderId,
      appId: FirebaseConfig.appId,
      measurementId: FirebaseConfig.measurementId,
    ),
  );

  await PushNotificationService.instance.ensureLocalNotificationsInitialized();
  await PushNotificationService.instance.showLocalNotification(message);
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isLocalNotificationsInitialized = false;
  bool _isForegroundListenersInitialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await ensureLocalNotificationsInitialized();
    await _requestNotificationPermissions();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _setupForegroundListeners();
    await syncTokenForActiveSession();
  }

  Future<void> ensureLocalNotificationsInitialized() async {
    if (_isLocalNotificationsInitialized) {
      return;
    }

    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotificationsPlugin.initialize(settings);
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_chatNotificationChannel);

    _isLocalNotificationsInitialized = true;
  }

  Future<void> _requestNotificationPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  void _setupForegroundListeners() {
    if (_isForegroundListenersInitialized) {
      return;
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
    _isForegroundListenersInitialized = true;
  }

  Future<void> showLocalNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final String title =
        notification?.title ??
        (message.data['title'] as String?) ??
        'New message';
    final String body =
        notification?.body ??
        (message.data['body'] as String?) ??
        'You received a new message';

    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _chatNotificationChannel.id,
        _chatNotificationChannel.name,
        channelDescription: _chatNotificationChannel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final int notificationId =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    await _localNotificationsPlugin.show(
      notificationId,
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  Future<void> syncTokenForActiveSession() async {
    final String? userId = await AuthSessionManager.getUserId();
    if (userId == null || userId.isEmpty) {
      await _tokenRefreshSubscription?.cancel();
      return;
    }
    await registerTokenForUser(userId);
  }

  Future<void> registerTokenForUser(String userId) async {
    if (userId.trim().isEmpty) {
      return;
    }

    final String? token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) {
      return;
    }

    await _saveTokenToUser(userId: userId, token: token);

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((
      String freshToken,
    ) async {
      await _saveTokenToUser(userId: userId, token: freshToken);
    });
  }

  Future<void> unregisterTokenForUser(String userId) async {
    if (userId.trim().isEmpty) {
      return;
    }

    final String? token = await _messaging.getToken();
    if (token != null && token.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(userId)
          .set(<String, dynamic>{
            FirebaseFields.fcmTokens: FieldValue.arrayRemove(<String>[token]),
            FirebaseFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .catchError((_) {});
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  Future<void> _saveTokenToUser({
    required String userId,
    required String token,
  }) async {
    await FirebaseFirestore.instance
        .collection(FirebaseCollections.users)
        .doc(userId)
        .set(<String, dynamic>{
          FirebaseFields.fcmTokens: FieldValue.arrayUnion(<String>[token]),
          FirebaseFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
