import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project2/view/login.dart';
import 'package:project2/view/staff/browser.dart';
import 'package:project2/view/staff/history_staff.dart';
import 'package:project2/view/staff/profile_staff.dart';

class Dashboard extends StatefulWidget {
  final String username; // 👈 รับ username จาก login

  const Dashboard({super.key, required this.username});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // ---------------------------------------------------------------
  // Dashboard data
  // ---------------------------------------------------------------
  int enableCount = 0;
  int pendingCount = 0;
  int reservedCount = 0;
  int disabledCount = 0;
  bool isLoading = true;

  // ---------------------------------------------------------------
  // Profile data
  // ---------------------------------------------------------------
  String profileName = '';
  String profileRole = '';
  String profileId = '';
  bool isProfileLoading = true;

  // ✅ ใช้ baseUrl เดียวกับ AuthApi
  final String baseUrl = AuthApi().baseUrl;

  // ---------------------------------------------------------------
  // ดึง token จาก SharedPreferences (ถ้ามี)
  // ---------------------------------------------------------------
  Future<Map<String, String>> _buildHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------------------------------------------------------------
  // Fetch Dashboard Data
  // ---------------------------------------------------------------
  Future<void> _fetchDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final headers = await _buildHeaders();

      final response = await http.get(
        Uri.parse("$baseUrl/api/staff/dashboard"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          enableCount = int.tryParse(data["enable_count"].toString()) ?? 0;
          pendingCount = int.tryParse(data["pending_count"].toString()) ?? 0;
          reservedCount = int.tryParse(data["reserved_count"].toString()) ?? 0;
          disabledCount = int.tryParse(data["disabled_count"].toString()) ?? 0;
          isLoading = false;
        });
      } else {
        print("❌ Failed to load dashboard: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("⚠️ Error fetching dashboard data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------
  // Fetch Profile Data
  // ---------------------------------------------------------------
  Future<void> _fetchProfileData() async {
    try {
      final headers = await _buildHeaders();
      final username = widget.username;

      final response = await http.get(
        Uri.parse("$baseUrl/api/profile/$username"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          profileName = data["username"] ?? '';
          profileRole = data["role_name"] ?? '';
          profileId = data["user_id"].toString();
          isProfileLoading = false;
        });
      } else {
        print("❌ Failed to load profile: ${response.statusCode}");
        setState(() => isProfileLoading = false);
      }
    } catch (e) {
      print("⚠️ Error fetching profile data: $e");
      setState(() => isProfileLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchProfileData();
  }

  // ---------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        // อยู่หน้า Main แล้ว ไม่ต้องทำอะไร
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileStaff(username: widget.username),
          ),
        );
        break;
    }
  }

  // ---------------------------------------------------------------
  // Logout Confirmation
  // ---------------------------------------------------------------
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
            onPressed: () async {
              // ถ้าใช้ SharedPreferences เก็บ token/uid ก็ลบออกตรงนี้ได้
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

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

  // ---------------------------------------------------------------
  // Build UI
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final Color mainAppColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
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
      // BODY
      // ------------------------------------------------------------
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchDashboardData();
          await _fetchProfileData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildProfileCard(context),
              const SizedBox(height: 20),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildDashboardCard(
                      context,
                      Icons.check,
                      'Enable',
                      enableCount,
                      [Colors.green.shade50, Colors.green.shade300],
                      Colors.green.shade800,
                    ),
                    _buildDashboardCard(
                      context,
                      Icons.hourglass_empty,
                      'Pending',
                      pendingCount,
                      [Colors.yellow.shade50, Colors.yellow.shade400],
                      Colors.yellow.shade800,
                    ),
                    _buildDashboardCard(
                      context,
                      Icons.lock_outline,
                      'Reserved',
                      reservedCount,
                      [Colors.red.shade50, Colors.red.shade300],
                      Colors.red.shade800,
                    ),
                    _buildDashboardCard(
                      context,
                      Icons.do_not_disturb_on_outlined,
                      'Disabled',
                      disabledCount,
                      [Colors.blueGrey.shade50, Colors.blueGrey.shade300],
                      Colors.blueGrey.shade800,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),

      // ------------------------------------------------------------
      // BOTTOM NAVIGATION
      // ------------------------------------------------------------
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: mainAppColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 0,
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

  // ---------------------------------------------------------------
  // Profile Card (แสดงเฉพาะ ID + Position)
  // ---------------------------------------------------------------
  Widget _buildProfileCard(BuildContext context) {
    if (isProfileLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 243, 243),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, size: 32, color: Colors.grey),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ แสดง ID เท่านั้น
                Text(
                  'ID: ${profileId.padLeft(5, '0')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                // ✅ แสดง Position จาก role_name
                Text(
                  'Position: $profileRole',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Dashboard Cards
  // ---------------------------------------------------------------
  Widget _buildDashboardCard(
    BuildContext context,
    IconData icon,
    String title,
    int count,
    List<Color> gradientColors,
    Color color,
  ) {
    return Card(
      elevation: 1,
      color: const Color.fromARGB(255, 223, 220, 220),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
