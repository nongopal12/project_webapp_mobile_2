import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project2/view/login.dart';
import 'history_user.dart';
import 'booking_room.dart';

class CheckStatusPage extends StatefulWidget {
  const CheckStatusPage({super.key});

  @override
  State<CheckStatusPage> createState() => _CheckStatusPageState();
}

class _CheckStatusPageState extends State<CheckStatusPage> {
  List<dynamic> bookingList = [];
  bool _loading = true;
  final String baseUrl = "http://172.27.11.178:3000";

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('uid') ?? 3;

      final response = await http.get(Uri.parse('$baseUrl/api/user/status/$userId'));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);

        // 🔸 Show only Pending (status = 1)
        setState(() {
          bookingList = data.where((b) => b['status'].toString() == '1').toList();
          _loading = false;
        });
      } else {
        throw Exception('Failed to load booking status');
      }
    } catch (e) {
      print("Error fetching status: $e");
      setState(() => _loading = false);
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  String _statusText(String code) {
    switch (code) {
      case '1':
        return 'Pending';
      case '2':
        return 'Approved';
      case '3':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(String code) {
    switch (code) {
      case '1':
        return const Color(0xFFE6D60A);
      case '2':
        return const Color(0xFF4CAF50);
      case '3':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String code) {
    switch (code) {
      case '1':
        return Icons.access_time;
      case '2':
        return Icons.check_circle_outline;
      case '3':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _timeSlot(int code) {
    switch (code) {
      case 1:
        return "8:00 - 10:00";
      case 2:
        return "10:00 - 12:00";
      case 3:
        return "13:00 - 15:00";
      case 4:
        return "15:00 - 17:00";
      default:
        return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : bookingList.isEmpty
                ? const Center(child: Text("No pending bookings"))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Check Pending Bookings',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...bookingList.map((booking) {
                          final code = booking['status'].toString();
                          return _buildBookingCard(booking, code);
                        }).toList(),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: _bottomNavBar(),
    );
  }

  Widget _buildBookingCard(dynamic booking, String code) {
    final color = _statusColor(code);
    final text = _statusText(code);
    final icon = _statusIcon(code);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAE7E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.location_on,
              'Room: ${booking['room_number']} (Floor ${booking['room_location']})'),
          _infoRow(Icons.calendar_today,
              'Date: ${booking['room_date'].toString().replaceAll("T", " ").replaceAll("Z", "")}'),
          _infoRow(Icons.access_time, 'Time: ${_timeSlot(booking['room_time'])}'),
          _infoRow(Icons.notes, 'Reason: ${booking['reason']}'),
          const SizedBox(height: 10),
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontSize: 15)),
          ]),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration:
                  BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
              child: Text(text, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.brown, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    );
  }

  Widget _bottomNavBar() {
    const brown = Color(0xFF6B2E1E);
    return Container(
      color: brown,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(
              icon: Icons.home,
              label: 'HOME',
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const UserHomePage()),
                  (route) => false,
                );
              },
            ),
            // 🔄 SWAPPED position: Check Status comes before History
            _BottomNavItem(
              icon: Icons.edit_note,
              label: 'Check Status',
              onTap: () {}, // already here
            ),
            _BottomNavItem(
              icon: Icons.history,
              label: 'History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
            ),
            _BottomNavItem(
              icon: Icons.logout,
              label: 'Logout',
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white24,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
