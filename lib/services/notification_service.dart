import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:sarkari_marg/screens/detail_screen.dart';

// Background Notification Handler (Must be a top-level independent function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? navigatorKey;

  static Future<void> init({GlobalKey<NavigatorState>? navKey}) async {
    navigatorKey = navKey;

    // 1. Request Notification Permission (Required for Android 13+ & iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    }

    // 2. Get Device Token & Subscribe to Topic 'all_users'
    try {
      String? token = await _messaging.getToken();
      debugPrint('🔥 FCM Device Token: $token');
      await _messaging.subscribeToTopic('all_users');
      debugPrint('✅ Subscribed to FCM topic: all_users');
    } catch (e) {
      debugPrint('⚠️ FCM Token/Topic Registration Error: $e');
    }

    // 3. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Setup Local Notifications for Foreground display
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handleNotificationClick(response.payload!);
        }
      },
    );

    // 5. Create High Importance Android Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for Sarkari Job alerts.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 6. Listen to Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        StyleInformation? styleInfo;
        String? imageUrl = notification.android?.imageUrl ??
            notification.apple?.imageUrl ??
            message.data['image'] ??
            message.data['image_url'];

        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final http.Response response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              styleInfo = BigPictureStyleInformation(
                ByteArrayAndroidBitmap(response.bodyBytes),
                largeIcon: ByteArrayAndroidBitmap(response.bodyBytes),
                contentTitle: notification.title,
                summaryText: notification.body,
              );
            }
          } catch (e) {
            debugPrint('Failed to download notification image: $e');
          }
        }

        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
              styleInformation: styleInfo,
            ),
          ),
          payload: message.data['slug'] ?? '',
        );
      }
    });

    // 7. Handle click when app was terminated/background
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final slug = initialMessage.data['slug'];
      if (slug != null && slug.isNotEmpty) _handleNotificationClick(slug);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final slug = message.data['slug'];
      if (slug != null && slug.isNotEmpty) _handleNotificationClick(slug);
    });
  }

  static void _handleNotificationClick(String slug) {
    if (slug.isEmpty || navigatorKey == null) return;
    debugPrint("Notification clicked for post slug: $slug");
    navigatorKey!.currentState?.push(
      MaterialPageRoute(builder: (_) => DetailScreen(slug: slug)),
    );
  }
}
