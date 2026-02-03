import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request Permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
      return;
    }

    // 2. Initialize Local Notifications (for foreground display)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Note: iOS permissions are requested via requestPermission above, 
    // but specific config here for foreground handling
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
        // You can add navigation logic here
      },
    );

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        
        // Filter: Proceed only if it looks like a chat message
        // Or simply show all notifications as requested "show notifications for messages"
        // Usually chat messages have a sender name in title and text in body
        _showForegroundNotification(message);
      }
    });

    // 4. Handle Background Message Taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Handle navigation
    });

    // 5. Get Token (optional, for debugging or verifying)
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    // Save token if needed locally or send to server in user_service
    await _saveTokenLocally(token);
    
    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenLocally);

    _isInitialized = true;
  }

  Future<void> _saveTokenLocally(String? token) async {
    if (token == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    // Check if notifications are enabled in app settings (shared prefs)
    final prefs = await SharedPreferences.getInstance();
    final bool pushEnabled = prefs.getBool('pushNotifications') ?? true;
    
    if (!pushEnabled) return;

    // "Show notification for messages new messages only"
    // We assume the payload or notification structure indicates a message
    // Use high importance channel for Android
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color:  Color(0xFF0C3C2B), // Use primary green
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  // Helper to send a test message (Simulated via code for testing triggers)
  // Real messages typically come from Backend API/Cloud Functions
}
