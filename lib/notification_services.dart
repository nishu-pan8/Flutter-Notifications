import 'dart:convert';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dynamic_dialogue.dart';

class NotificationServices {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late BuildContext context;


  Future<void> setupMessages() async {
    RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      handleNavigation(message);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(handleNavigation);
  }

  Future<void> handleNavigation(RemoteMessage message) async {
    String apiUrl = 'http://10.0.2.2:3000/notification';
    var response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      if (kDebugMode) {
        print(response.body);
      }
    } else {
      if (kDebugMode) {
        print('API call failed');
      }
    }
  }

  void requestNotificationPermission() async {
    //send notifications to users
    NotificationSettings settings = await messaging.requestPermission(
      alert: true, //displays notifications
      announcement: true, //siri
      badge: true, //app icons
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('user granted permission');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('user granted provisional permission');
      }
    } else {
      AppSettings.openNotificationSettings();
      if (kDebugMode) {
        print('user denied permission');
      }
    }
  }

  void createChannel(AndroidNotificationChannel channel) async {
    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showNotificationWeb(BuildContext context) async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
      }
      if (kDebugMode) {
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print(
              'Message also contained a notification: ${message.notification!.body}');
        }
        showDialog(
            context: context,
            builder: ((BuildContext context) {
              return DynamicDialog(
                  title: message.notification!.title!,
                  body: message.notification!.body!);
            }));
      }
    });
  }

  //App is active
  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      RemoteNotification? notification = message.notification;
      // AndroidNotification? android = message.notification!.android;

      if (kDebugMode) {
        print("notifications title: ${notification!.title}");
        print("notifications body: ${notification.body}");
        print('data:${message.data.toString()}');
        print('type:${message.data['type']}');
        print('id:${message.data['id']}');
      }

      if (kIsWeb) {
        print('----------------');
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        foregroundMessage();
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        initializeNotifications();
        showNotificationMobile(message);
      }
    });
  }

  Future foregroundMessage() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: darwinInitializationSettings,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'messages',
      'Messages',
      description: 'This is for flutter firebase',
      importance: Importance.max,
    );
    createChannel(channel);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((event) {
      final notification = event.notification;
      final android = event.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
                android: AndroidNotificationDetails(channel.id, channel.name,
                    channelDescription: channel.description,
                    icon: android.smallIcon,
                    priority: Priority.high,
                    importance: Importance.max)));
      }
    });
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (payload) {
      Navigator.pushNamed(context, '/chat');
    });
  }

  Future<void> showNotificationMobile(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      message.notification!.android!.channelId.toString(),
      message.notification!.android!.channelId.toString(),
      importance: Importance.max,
      showBadge: true,
      playSound: true,
    );

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
            channel.id.toString(), channel.name.toString(),
            channelDescription: 'your channel description',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            ticker: 'ticker',
            sound: channel.sound
            //     sound: RawResourceAndroidNotificationSound('jetsons_doorbell')
            //  icon: largeIconPath
            );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true);

    NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails, iOS: darwinNotificationDetails);

    Future.delayed(Duration.zero, () {
      flutterLocalNotificationsPlugin.show(
        1,
        message.notification!.title.toString(),
        message.notification!.body.toString(),
        notificationDetails,
      );
    });
  }

  sendPushMessageToWeb() async {
    String? token = await messaging.getToken();
    if (token == null) {
      if (kDebugMode) {
        print('Unable to send FCM message, no token exists.');
      }
      return;
    }
    try {
      await http
          .post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
          'key=AAAAqvcMMcc:APA91bFmgFlxzOmeFeoSmpGbjKU1nZ27YXFS21_tHlS5BUfe6Awx4PxeSvfz-3U7ZpdTL9P3s4hhrReFvY-uIl_vzeiW9-3NPX-AQKlTgLkxJSpLXC2c0fIrBxrM1_0QhoGmkyhCgirA'
        },
        body: json.encode({
          'to': token,
          'message': {
            'token': token,
          },
          "notification": {
            "title": "Push Notification",
            "body": "Firebase  push notification"
          }
        }),
      )
          .then((value) => print(value.body));
      if (kDebugMode) {
        print('FCM request for web sent!');
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }
}

