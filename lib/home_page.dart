import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'notification_services.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  NotificationServices notificationServices = NotificationServices();

  @override
  void initState() {
    super.initState();
    notificationServices.requestNotificationPermission();
    notificationServices.setupMessages();
    notificationServices.firebaseInit(context);
    notificationServices.initializeNotifications();
    notificationServices.messaging.getToken().then((value) {
      if (kDebugMode) {
        print('device token');
        print(value);
      }
    });
  }

  void subscribeToTopicMobile() async {
    await FirebaseMessaging.instance
        .subscribeToTopic("topic1")
        .then((value) => debugPrint("User 1 subscribed"));
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      notificationServices.showNotificationMobile(message);
    });
  }


  @override
  Widget build(BuildContext context) {
    if(kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(10),
            elevation: 10,
            child: ListTile(
              title: Center(
                child: OutlinedButton.icon(
                  label: const Text('Push Notification',
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  onPressed: () {
                    notificationServices.sendPushMessageToWeb();
                  }, icon: const Icon(Icons.notifications),
                ),
              ),
            ),
          ),
        )
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                notificationServices.messaging.getToken().then((value) async {
                  var data = {
                    'to': value.toString(),
                    'priority': 'high',
                    'notification': {
                      'title': 'Hello! Good Morning !!',
                      'body': 'Nishu',
                      "sound": "jetsons_doorbell.mp3"
                    },
                    'data': {'type': 'chat', 'id': '12345'}
                  };

                  await http.post(
                      Uri.parse('https://fcm.googleapis.com/fcm/send'),
                      body: jsonEncode(data),
                      headers: {
                        'Content-Type': 'application/json; charset=UTF-8',
                        'Authorization':
                        'key=AAAAqvcMMcc:APA91bFmgFlxzOmeFeoSmpGbjKU1nZ27YXFS21_tHlS5BUfe6Awx4PxeSvfz-3U7ZpdTL9P3s4hhrReFvY-uIl_vzeiW9-3NPX-AQKlTgLkxJSpLXC2c0fIrBxrM1_0QhoGmkyhCgirA'
                      }).then((value) {
                    if (kDebugMode) {
                      print(value.body.toString());
                    }
                  }).onError((error, stackTrace) {
                    if (kDebugMode) {
                      print(error);
                    }
                  });
                });
              },
              child: const Text('Send Notifications'),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {
            subscribeToTopicMobile();
          }, child: const Text('Subscribe for Mobile')),
        ],
      ),
    );
  }
}