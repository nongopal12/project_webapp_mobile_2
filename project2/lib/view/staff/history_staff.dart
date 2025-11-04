import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project2/view/login.dart';
import 'package:project2/view/staff/browser.dart';
import 'package:project2/view/staff/dashboard.dart';
import 'package:project2/view/staff/profile_staff.dart';

// -----------------------------------------------------------------
// Data Model (ลบ approvedBy ออกแล้ว)
// -----------------------------------------------------------------
class HistoryItem {
  final int id;
  final String name;
  final String room;
  final String date;
  final String time;
  final String reason;
  final String status;

  HistoryItem({
    required this.id,
    required this.name,
    required this.room,
    required this.date,
    required this.time,
    required this.reason,
    required this.status,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as int,
      name: json['name'] as String,
      room: json['room'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String,
    );
  }
}

// -----------------------------------------------------------------
// HistoryStaff Page
// -----------------------------------------------------------------
class HistoryStaff extends StatefulWidget {
  final String username; // 👈 รับ username

  const HistoryStaff({super.key, required this.username});

  @override
  State<HistoryStaff> createState() => _HistoryStaffState();
}

class _HistoryStaffState extends State<HistoryStaff> {
  late Future<List<HistoryItem>> _historyFuture;
  final String apiUrl = 'http://192.168.1.112:3000/api/staff/history';

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
        throw Exception(
          'Failed to load history (Status ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = _fetchHistory();
    });
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
      body: FutureBuilder<List<HistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _refreshHistory,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshHistory,
              child: ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 100.0),
                    child: Center(child: Text('No history found.')),
                  ),
                ],
              ),
            );
          }

          final historyList = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                final item = historyList[index];

                return _buildHistoryCard(
                  context,
                  name: item.name,
                  room: item.room,
                  date: item.date,
                  time: item.time,
                  reason: item.reason,
                  status: item.status,
                );
              },
            ),
          );
        },
      ),
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

  // -----------------------------------------------------------------
  // History Card UI (ลบ Approved by ออกแล้ว)
  // -----------------------------------------------------------------
  Widget _buildHistoryCard(
    BuildContext context, {
    required String name,
    required String room,
    required String date,
    required String time,
    required String reason,
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "Room: $room",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  backgroundColor: statusColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildInfoRow(context, Icons.person, "Name: $name"),
            _buildInfoRow(context, Icons.calendar_today, "Date: $date"),
            _buildInfoRow(context, Icons.access_time, "Time: $time"),
            if (status == "Reject" && reason.isNotEmpty)
              _buildInfoRow(context, Icons.notes, "Reason: $reason"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text, {
    TextStyle? style,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: style ?? const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
