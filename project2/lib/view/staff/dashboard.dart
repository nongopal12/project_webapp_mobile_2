import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:project2/view/login.dart';
import 'package:project2/view/staff/browser.dart';
import 'package:project2/view/staff/history_staff.dart';
import 'package:project2/view/staff/profile_staff.dart';
import 'package:project2/view/staff/Room_browser_staff.dart';

/// ===== QuickRoom Theme =====
class SColors {
  static const Color bg = Color(0xFFF7F7F9);
  static const Color primaryRed = Color.fromARGB(255, 136, 60, 48);
  static const Color gold = Color(0xFFCC9A2B);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF2E2E2E);
}

class Dashboard extends StatefulWidget {
  final String username;

  const Dashboard({super.key, required this.username});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int enableCount = 0;
  int pendingCount = 0;
  int reservedCount = 0;
  int disabledCount = 0;
  bool isLoading = true;

  String profileName = '';
  String profileRole = '';
  String profileEmail = '';
  bool isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchProfileData();
  }

  // ================================
  // Fetch Dashboard Data
  // ================================
  Future<void> _fetchDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse("http://172.27.13.156:3000/api/staff/dashboard"),
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
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ================================
  // Fetch Profile Data
  // ================================
  Future<void> _fetchProfileData() async {
    try {
      final response = await http.get(
        Uri.parse("http://172.27.13.156:3000/api/profile/${widget.username}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          profileName = data["username"] ?? '';
          profileRole = data["role_name"] ?? '';
          profileEmail = data["user_email"] ?? '';
          isProfileLoading = false;
        });
      }
    } catch (e) {
      setState(() => isProfileLoading = false);
    }
  }

  // ================================
  // Logout Function
  // ================================
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
              backgroundColor: SColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ================================
  // Build UI
  // ================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: "Quick",
                style: TextStyle(color: SColors.gold),
              ),
              TextSpan(
                text: "Room",
                style: TextStyle(color: SColors.primaryRed),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: SColors.primaryRed.withOpacity(0.1),
              child: const Icon(Icons.exit_to_app, color: SColors.primaryRed),
            ),
            onPressed: _logout,
          ),
          const SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[300], height: 1),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchDashboardData();
          await _fetchProfileData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(),
              const SizedBox(height: 20),
              _buildBrowseRoomsButton(),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _buildDashboardGrid(),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: SColors.primaryRed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => Browser(username: widget.username),
                ),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryStaff(username: widget.username),
                ),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileStaff(username: widget.username),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Main"),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: "Edit"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  // ================================
  // Profile Card (Same as Approver Style)
  // ================================
  Widget _buildProfileCard() {
    if (isProfileLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SColors.primaryRed.withOpacity(0.12),
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: SColors.primaryRed,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileName,
                  style: const TextStyle(
                    color: SColors.primaryRed,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Email: $profileEmail",
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Role: $profileRole",
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================
  // Browse Rooms Button (ตามรูป)
  // ================================
  Widget _buildBrowseRoomsButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RoomBrowserPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.meeting_room_outlined, color: Colors.black, size: 20),
            SizedBox(width: 8),
            Text(
              "Browse Rooms",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================
  // Dashboard Grid
  // ================================
  Widget _buildDashboardGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildDashboardCard(
          Icons.check_circle,
          "Enable",
          enableCount,
          Colors.green,
        ),
        _buildDashboardCard(
          Icons.hourglass_bottom,
          "Pending",
          pendingCount,
          Colors.orange,
        ),
        _buildDashboardCard(Icons.lock, "Reserved", reservedCount, Colors.red),
        _buildDashboardCard(
          Icons.block,
          "Disabled",
          disabledCount,
          Colors.grey,
        ),
      ],
    );
  }

  // ================================
  // Dashboard Card (Icon inline with text)
  // ================================
  Widget _buildDashboardCard(
    IconData icon,
    String title,
    int count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // icon + title อยู่บรรทัดเดียว
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "$count",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
