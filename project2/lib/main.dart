import 'package:flutter/material.dart';
import 'package:project2/view/staff/dashboard.dart';
// import 'package:project2/view/staff/dashboard.dart';

void main() {
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Booking System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const Dashboard(), // หน้าแรกเป็น Dashboard
    );
  }
}
