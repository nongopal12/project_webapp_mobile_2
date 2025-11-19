import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project2/view/login.dart';
import 'package:project2/view/staff/browser.dart';
import 'package:project2/view/staff/dashboard.dart';
import 'package:project2/view/staff/profile_staff.dart';

// ---------------------------------------------------------
// Data Model
// ---------------------------------------------------------
class HistoryItem {
  final int id;
  final String name;
  final String room;
  final String date;
  final String time;
  final String reason;
  final String status;
  final String approverName;
  final String approverComment;

  HistoryItem({
    required this.id,
    required this.name,
    required this.room,
    required this.date,
    required this.time,
    required this.reason,
    required this.status,
    required this.approverName,
    required this.approverComment,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      name: json['name'],
      room: json['room'],
      date: json['date'],
      time: json['time'],
      reason: json['reason'] ?? '',
      status: json['status'],
      approverName: json['approver_name'] ?? "-",
      approverComment: json['approver_comment'] ?? "",
    );
  }
}

// ---------------------------------------------------------
// HistoryStaff Page
// ---------------------------------------------------------
class HistoryStaff extends StatefulWidget {
  final String username;

  const HistoryStaff({super.key, required this.username});

  @override
  State<HistoryStaff> createState() => _HistoryStaffState();
}

class _HistoryStaffState extends State<HistoryStaff> {
  late Future<List<HistoryItem>> _historyFuture;

  final String apiUrl = 'http://192.168.1.123:3000/api/staff/history';

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<HistoryItem>> _fetchHistory() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((item) => HistoryItem.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load history");
      }
    } catch (e) {
      throw Exception("Fetch error: $e");
    }
  }

  // เพิ่มฟังก์ชัน refresh
  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = _fetchHistory();
    });
  }

  // ---------------------------------------------------------
  // Logout
  // ---------------------------------------------------------
  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF883C31),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // Bottom Navigation
  // ---------------------------------------------------------
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Dashboard(username: widget.username),
          ),
        );
        break;

      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Browser(username: widget.username)),
        );
        break;

      case 2:
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
  }

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF883C31);
    const Color accentColor = Color(0xFFD7A04E);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: "Quick",
                style: TextStyle(color: mainColor),
              ),
              TextSpan(
                text: "Room",
                style: TextStyle(color: accentColor),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: mainColor),
            onPressed: _logout,
          ),
          const SizedBox(width: 10),
        ],
      ),

      // BODY - เพิ่ม RefreshIndicator
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        color: mainColor,
        child: FutureBuilder<List<HistoryItem>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text("No history available")),
                ],
              );
            }

            final history = snapshot.data!;

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                return _buildHistoryCard(history[index]);
              },
            );
          },
        ),
      ),

      // NAV BAR - เปลี่ยนสีพื้นหลังเป็นสีขาว และไอคอนเป็นสี mainColor
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: mainColor,
        selectedItemColor: Colors.white,
        currentIndex: 2,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Main"),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: "Edit"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // History Card
  // ---------------------------------------------------------
  Widget _buildHistoryCard(HistoryItem item) {
    final Color mainColor = Color(0xFF883C31);

    Color statusColor = item.status == "Approved"
        ? Colors.green
        : item.status == "Reject"
        ? Colors.red
        : Colors.orange;

    return Card(
      color: const Color.fromARGB(255, 243, 240, 240),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER + STATUS BADGE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Room: ${item.room}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _infoRow(Icons.person, "Name: ${item.name}"),
            _infoRow(Icons.calendar_today, "Date: ${item.date}"),
            _infoRow(Icons.access_time, "Time: ${item.time}"),

            // Approver
            _infoRow(Icons.verified_user, "Approver by: ${item.approverName}"),

            // Reject reason (เฉพาะ Reject)
            if (item.status == "Reject" && item.approverComment.isNotEmpty)
              _infoRow(Icons.comment, "Reject Reason: ${item.approverComment}"),

            // Booking reason (แสดงทุกสถานะ)
            _infoRow(Icons.info, "Booking Reason: ${item.reason}"),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Color(0xFF883C31)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
