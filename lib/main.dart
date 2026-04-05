import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/constants/api_keys.dart';
import 'package:vidyarth_app/core/theme.dart';
import 'package:vidyarth_app/features/splash/screens/splash_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
      url: ApiKeys.supabaseUrl,
      // url: "https://supabase-api.kartiktulsian1705.workers.dev",
      anonKey: ApiKeys.supabaseAnonKey,
  );

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
  
  runApp(const MyApp());
}

Future<void> requestNotificationPermissions() async {
  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  if (androidImplementation != null) {
    await androidImplementation.requestNotificationsPermission();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vidyarth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}