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

  final String baseUrl = "http://192.168.0.101:3000"; // for Android emulator
  

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('uid') ?? 3; // fallback for testing
      final response = await http.get(Uri.parse('$baseUrl/api/user/status/$userId'));

      if (response.statusCode == 200) {
        setState(() {
          bookingList = json.decode(response.body);
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
        return const Color(0xFFE6D60A); // yellow
      case '2':
        return const Color(0xFF4CAF50); // green
      case '3':
        return const Color(0xFFF44336); // red
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
                ? const Center(child: Text("No booking status found"))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Check Booking Status',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...bookingList.map((booking) {
                          final statusCode = booking['status'].toString();
                          final statusText = _statusText(statusCode);
                          final statusColor = _statusColor(statusCode);
                          final statusIcon = _statusIcon(statusCode);

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
                                const SizedBox(height: 8),
                               // _infoRow(Icons.calendar_today, 'Date: ${booking['room_date']}'),
                               _infoRow(Icons.calendar_today, 'Date: ${booking['room_date'].toString().replaceAll("T", " ").replaceAll("Z", "")}'),

                                const SizedBox(height: 8),
                                _infoRow(Icons.access_time,
                                    'Time: ${_timeSlot(booking['room_time'])}'),
                                const SizedBox(height: 8),
                                _infoRow(Icons.notes, 'Reason: ${booking['reason']}'),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Icon(statusIcon, color: statusColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      statusText,
                                      style: const TextStyle(
                                          fontSize: 15, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: _bottomNavBar(),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.brown, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
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
              icon: Icons.edit_note,
              label: 'Check Status',
              onTap: () {}, // Already here
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
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


