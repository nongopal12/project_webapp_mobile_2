import 'package:flutter/material.dart';
import 'package:project_mobile_app2/views/login.dart'; // ✅ import หน้า Login
import 'package:project_mobile_app2/views/staff/dashboard.dart'; // เผื่อใช้ตอนทดสอบ

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color mainAppColor = Color(0xFF883C31); // สีน้ำตาลแดง
    const Color accentColor = Color(0xFFFFCC00); // สีเหลือง

    return MaterialApp(
      title: 'QuickRoom Staff',
      theme: ThemeData(
        primaryColor: mainAppColor,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: mainAppColor,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: mainAppColor,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: mainAppColor,
          primary: mainAppColor,
          secondary: accentColor,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(), // ✅ หน้าแรกคือ LoginPage
    );
  }
}
