import 'package:flutter/material.dart';
import 'package:project2/view/login.dart';
import 'package:project2/view/staff/browser.dart';
import 'package:project2/view/staff/dashboard.dart';
import 'package:project2/view/staff/history_staff.dart';
import 'package:project2/view/staff/profile_staff.dart';

class ProfileStaff extends StatefulWidget {
  const ProfileStaff({super.key});

  @override
  State<ProfileStaff> createState() => _ProfileStaffState();
}

class _ProfileStaffState extends State<ProfileStaff> {
  // ================================================================
  // ฟังก์ชัน Logout
  // ================================================================
  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF883C31),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully.')),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // การเปลี่ยนหน้า (Bottom Navigation)
  // ================================================================
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Browser()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HistoryStaff()),
        );
        break;
      case 3:
        break;
    }
  }

  // ================================================================
  // Build หน้าโปรไฟล์ใหม่ (ใช้รูปภาพแทน UI การ์ด)
  // ================================================================
  @override
  Widget build(BuildContext context) {
    final Color mainAppColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      // ------------------------------------------------------------
      // AppBar ด้านบน
      // ------------------------------------------------------------
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: 'Quick',
                style: TextStyle(color: mainAppColor),
              ),
              TextSpan(
                text: 'Room',
                style: TextStyle(color: accentColor),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(Icons.exit_to_app, color: mainAppColor, size: 24),
            ),
            onPressed: _logout,
          ),
          const SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[300], height: 1.0),
        ),
      ),

      // ------------------------------------------------------------
      // BODY: แสดงภาพโปรไฟล์เต็มหน้า
      // ------------------------------------------------------------
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/Profile_staff.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Text(
                'Image not found: profile_staff.jpg',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),

      // ------------------------------------------------------------
      // Bottom Navigation Bar
      // ------------------------------------------------------------
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: mainAppColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 3,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Main'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Edit'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
