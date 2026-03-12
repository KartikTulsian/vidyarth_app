import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/theme.dart';
import 'package:vidyarth_app/features/splash/screens/splash_screen.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
      // url: "https://tqiusinnilketoemiihv.supabase.co",
      url: "https://supabase-api.kartiktulsian1705.workers.dev",
      anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxaXVzaW5uaWxrZXRvZW1paWh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTA4MDIsImV4cCI6MjA4NDEyNjgwMn0.NRd39gNcOMmejKtfwIkqxrzUL8Hb2YHMLrs3zxe1rZE",
  );
  
  runApp(const MyApp());
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