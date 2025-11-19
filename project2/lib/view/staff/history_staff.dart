import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project2/view/login.dart';
import 'package:project2/view/staff/browser.dart';
import 'package:project2/view/staff/dashboard.dart';
import 'package:project2/view/staff/profile_staff.dart';

/// ===== QuickRoom Theme =====
class SColors {
  static const Color bg = Color(0xFFF7F7F9);
  static const Color primaryRed = Color.fromARGB(255, 136, 60, 48);
  static const Color gold = Color(0xFFCC9A2B);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF2E2E2E);
}

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
              backgroundColor: SColors.primaryRed,
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
    return Scaffold(
      backgroundColor: SColors.bg, // 🔥 พื้นหลังสีเทาอ่อน
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
              child: const Icon(
                Icons.exit_to_app,
                color: SColors.primaryRed,
                size: 24,
              ),
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
        onRefresh: _refreshHistory,
        color: SColors.primaryRed,
        child: FutureBuilder<List<HistoryItem>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _refreshHistory,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      "No history available",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
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

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: SColors.primaryRed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
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
    Color statusColor = item.status == "Approved"
        ? Colors.green
        : item.status == "Reject"
        ? Colors.red
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SColors.card, // 🔥 การ์ดสีขาว
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 HEADER + STATUS BADGE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Room: ${item.room}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: SColors.text,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _infoRow(Icons.person, "Name: ${item.name}"),
            _infoRow(Icons.calendar_today, "Date: ${item.date}"),
            _infoRow(Icons.access_time, "Time: ${item.time}"),
            _infoRow(Icons.verified_user, "Approver by: ${item.approverName}"),

            // 🔥 Reject reason (เฉพาะ Reject)
            if (item.status == "Reject" && item.approverComment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.comment, size: 18, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Reject Reason: ${item.approverComment}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 🔥 Booking reason (แสดงทุกสถานะ)
            if (item.reason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Booking Reason: ${item.reason}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
          Icon(icon, size: 18, color: SColors.primaryRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: SColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
