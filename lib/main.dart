import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'splash_screen.dart';
import 'video_list_screen.dart';
import 'foreground_task_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Android 13 이상 알림 권한 요청
  if (await FlutterForegroundTask.checkNotificationPermission() !=
      NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }

  // ✅ Firebase 초기화
  try {
    await Firebase.initializeApp();
    print("🔥 Firebase 초기화 성공!");
  } catch (e) {
    print("🔥 Firebase 초기화 실패: $e");
  }

  // ✅ 로컬 알림 초기화
  const initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // ✅ Foreground Task 초기화 (주의: await ❌)
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'dreaming_cat_channel_id',
      channelName: '꿈꾸는 고양이 수면 알림',
      channelDescription: '수면 중에도 재생이 유지됩니다',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      iconData: const NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: const ForegroundTaskOptions(
      isOnceEvent: false,
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  // ✅ taskHandler 등록
  FlutterForegroundTask.setTaskHandler(MyForegroundTaskHandler());

  // ✅ 앱 실행
  runApp(const WithForegroundTask(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '꿈꾸는고양이',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        useMaterial3: false,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const VideoListScreen(),
      },
    );
  }
}
