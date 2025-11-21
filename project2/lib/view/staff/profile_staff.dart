import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project2/view/login.dart';
import 'package:project2/view/staff/browser.dart';
import 'package:project2/view/staff/dashboard.dart';
import 'package:project2/view/staff/history_staff.dart';

const String kBaseUrl = "http://172.27.13.156:3000";

class PColors {
  static const bg = Color(0xFFF7F7F9);
  static const primaryRed = Color(0xFF883C31);
  static const gold = Color(0xFFD7A04E);
  static const card = Colors.white;
  static const text = Color(0xFF2E2E2E);
}

class ProfileStaff extends StatefulWidget {
  final String username;

  const ProfileStaff({super.key, required this.username});

  @override
  State<ProfileStaff> createState() => _ProfileStaffState();
}

class _ProfileStaffState extends State<ProfileStaff> {
  bool _loading = true;
  String? _error;

  int? _userId;
  String _username = '';
  String _email = '';
  String _role = 'Staff';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final username = widget.username;
      final uri = Uri.parse('$kBaseUrl/api/profile/$username');
      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('โหลดโปรไฟล์ไม่สำเร็จ');
      final data = json.decode(res.body);
      _userId = int.tryParse('${data['user_id'] ?? data['id'] ?? ''}');
      _username = (data['username'] ?? '').toString();
      _email = (data['user_email'] ?? '').toString();
      _role = (data['role_name'] ?? 'Staff').toString();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

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
              backgroundColor: PColors.primaryRed,
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

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Dashboard(username: widget.username),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Browser(username: widget.username),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryStaff(username: widget.username),
          ),
        );
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainAppColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: PColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('ผิดพลาด: $_error'))
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: EmployeeIdCardHorizontal(
                  name: _username.isEmpty ? '-' : _username,
                  role: _role,
                  employeeId: _userId == null ? '-' : '#${_userId!}',
                  email: _email,
                  department: 'QuickRoom System',
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: mainAppColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        selectedFontSize: 14,
        unselectedFontSize: 12,
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

/// ===== บัตรพนักงานแนวนอน (ไม่มีรูป) =====
class EmployeeIdCardHorizontal extends StatelessWidget {
  final String name;
  final String role;
  final String employeeId;
  final String department;
  final String email;

  const EmployeeIdCardHorizontal({
    super.key,
    required this.name,
    required this.role,
    required this.employeeId,
    required this.department,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 360;
    const double cardHeight = 230;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [PColors.primaryRed, Color(0xFF5A1F18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // แถบทองด้านบน
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 42,
            child: Container(
              color: PColors.gold,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'EMPLOYEE CARD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          // เนื้อใน
          Positioned.fill(
            top: 42,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ช่องซ้าย (แทนรูป)
                  Container(
                    width: 100,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(.6),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: PColors.primaryRed,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // ช่องขวา (ข้อมูล)
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            role,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _kv('ID', employeeId),
                          _kv('Department', department),
                          _kv('Email', email),
                          const SizedBox(height: 10),
                          Container(
                            width: 140,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // มุมล่างขวา
          Positioned(
            right: 14,
            bottom: 8,
            child: Text(
              employeeId,
              style: TextStyle(
                color: Colors.white.withOpacity(.95),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$k :',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(fontSize: 12.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
