// import 'package:flutter/material.dart';
// //import 'package:flutter_course/week09/Drawer_demo.dart';
// //import 'package:flutter_course/week09/drawer_widget.dart';

// void main() {
//   runApp(MaterialApp(home: DrawerDemo()));
// }
import 'package:flutter/material.dart';
import 'package:project2/view/user/checkstatus.dart';
import 'package:project2/view/user/history_user.dart';

void main() {
  runApp(const MyTestApp());
}

class MyTestApp extends StatelessWidget {
  const MyTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TestMenu(),
    );
  }
}

class TestMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TEST MENU")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Open History Page"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Open Check Status Page"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckStatusPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

