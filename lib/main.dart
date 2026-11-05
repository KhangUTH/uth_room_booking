import "package:flutter/material.dart";
import "package:uth_room_booking/theme/app_theme.dart";
import "package:uth_room_booking/features/splash/presentation/splash_screen.dart";

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
