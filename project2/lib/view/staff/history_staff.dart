import 'package:flutter/material.dart';
import 'package:project2/view/login.dart';
import 'package:project2/view/staff/browser.dart';
import 'package:project2/view/staff/dashboard.dart';
import 'package:project2/view/staff/profile_staff.dart';

class HistoryStaff extends StatefulWidget {
  const HistoryStaff({super.key});

  @override
  State<HistoryStaff> createState() => _HistoryStaffState();
}

class _HistoryStaffState extends State<HistoryStaff> {
  // ================================================================
  // Section 1: ฟังก์ชัน Logout
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
  // Section 2: Navigation เมนูด้านล่าง
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
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileStaff()),
        );
        break;
    }
  }

  // ================================================================
  // Section 3: เนื้อหาหลักของหน้า
  // ================================================================
  @override
  Widget build(BuildContext context) {
    final Color mainAppColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      // ------------------------------------------------------------
      // AppBar
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
      // Body (รายการประวัติการจอง)
      // ------------------------------------------------------------
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHistoryCard(
            context,
            name: "Ronaldo",
            email: "Ronaldo123@gmail.com",
            room: "Room 101",
            time: "8:00pm - 10:00pm",
            reason: "Work with friend",
            approvedBy: "Ajarn ABC",
            status: "Approved",
          ),
          _buildHistoryCard(
            context,
            name: "Benzema",
            email: "Benzema123@gmail.com",
            room: "Room 102",
            time: "6:00pm - 8:00pm",
            reason: "Group Project Meeting",
            approvedBy: "Ajarn DEF",
            status: "Approved",
          ),
          _buildHistoryCard(
            context,
            name: "Bale",
            email: "Bale123@gmail.com",
            room: "Room 103",
            time: "9:00am - 11:00am",
            reason: "Research Discussion",
            approvedBy: "Ajarn GHI",
            status: "Pending",
          ),
          _buildHistoryCard(
            context,
            name: "Toon",
            email: "Toon123@gmail.com",
            room: "Room 104",
            time: "1:00pm - 3:00pm",
            reason: "Study Group",
            approvedBy: "Ajarn JKL",
            status: "Reject",
          ),
        ],
      ),

      // ------------------------------------------------------------
      // Bottom Navigation Bar
      // ------------------------------------------------------------
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: mainAppColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 2,
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

  // ================================================================
  // Section 4: ฟังก์ชันสร้างการ์ดประวัติแต่ละรายการ
  // ================================================================
  Widget _buildHistoryCard(
    BuildContext context, {
    required String name,
    required String email,
    required String room,
    required String time,
    required String reason,
    required String approvedBy,
    required String status,
  }) {
    Color statusColor;
    switch (status) {
      case "Approved":
        statusColor = Colors.green;
        break;
      case "Pending":
        statusColor = Colors.orange;
        break;
      case "Reject":
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      color: const Color.fromARGB(255, 223, 220, 220),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context, Icons.person, "Name: $name"),
            _buildInfoRow(context, Icons.email, "Email: $email"),
            _buildInfoRow(context, Icons.room, "Room: $room"),
            _buildInfoRow(context, Icons.access_time, "Time: $time"),
            _buildInfoRow(context, Icons.notes, "Reason: $reason"),
            _buildInfoRow(
              context,
              Icons.check_circle_outline,
              "Approved by: $approvedBy",
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Chip(
                label: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: statusColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // Section 5: แถวข้อมูลแต่ละบรรทัดในการ์ด
  // ================================================================
  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
