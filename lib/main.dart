import 'dart:async';

import 'package:auto_start_flutter/auto_start_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
late AndroidNotificationChannel channel;
bool isFlutterLocalNotificationsInitialized = false;
const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
final InitializationSettings initializationSettings = InitializationSettings(
  android: initializationSettingsAndroid,
);

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  isFlutterLocalNotificationsInitialized = true;
}

Future<void> showNotifications() async {
  flutterLocalNotificationsPlugin.show(
    124124,
    'notification.title',
    'notification.body',
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        styleInformation: BigTextStyleInformation('Big text'),
      ),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> callbackDispatcher() async {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> showNotifications() async {
    flutterLocalNotificationsPlugin.show(
      124124,
      'notification.title',
      'notification.body',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'channel.id',
          'channel.name',
          styleInformation: BigTextStyleInformation(
            '''
            <!DOCTYPE html>
            <html>
            <body>
            <h1>My First Heading</h1>
            <p>My first paragraph.</p>
            </body>
            </html>
          ''',
            htmlFormatBigText: true,
          ),
        ),
      ),
    );
  }

  Workmanager().executeTask((task, inputData) async {
    await showNotifications();

    print(task);
    if (task == 'registerOneOffTask') {
      return Future.value(false);
    } else {
      return Future.value(true);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupFlutterNotifications();
  flutterLocalNotificationsPlugin.initialize(initializationSettings).then((value) {
    print(value);
  });

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    //initAutoStart();
  }

  Future<void> initAutoStart() async {
    try {
      var test = (await isAutoStartAvailable) ?? false;
      print(test);

      if (test) await getAutoStartPermission();
    } on PlatformException catch (e) {
      print(e);
    }
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool periodicTask = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () async {
                showNotifications();
              },
              child: const Text('Send Notifications'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('PeriodicTask '),
                CupertinoSwitch(value: periodicTask, onChanged: (value) => setState(() => periodicTask = value)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await Workmanager().cancelAll();
                if (!periodicTask) {
                  await Workmanager().registerOneOffTask(
                    "oneoff-task-identifier",
                    "registerOneOffTask",
                  );
                } else {
                  await Workmanager().registerPeriodicTask(
                    'uniqueTaskIdentifier',
                    'registerPeriodicTask',
                  );
                }
              },
              child: const Text('Register work'),
            ),
          ],
        ),
      ),
    );
  }
}
