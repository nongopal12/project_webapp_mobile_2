import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project2/view/login.dart';
import 'checkstatus.dart';
import 'booking_room.dart';
import 'package:project2/view/login.dart'; // ใช้ AuthApi

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> bookingHistory = [];
  bool _loading = true;

  // ✅ ใช้ baseUrl เดียวกับ login
  final String baseUrl = AuthApi().baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('uid');
      String? token = prefs.getString('token'); // ถ้ายังไม่มี JWT ก็จะเป็น null

      // ❗ ถ้าไม่รู้ว่า user ไหนจริง ๆ ค่อยเด้งกลับ login
      if (userId == null) {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired, please login again'),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
        return;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/history/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          bookingHistory = data
              .where(
                (item) =>
                    item['status'].toString() == '2' ||
                    item['status'].toString() == '3',
              )
              .toList();
          _loading = false;
        });
      } else if (response.statusCode == 401) {
        // กรณี backend บังคับ JWT แล้ว token ไม่ถูกต้อง
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unauthorized, please login again')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      } else {
        throw Exception(
          'Failed to load booking history: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error: $e');
      setState(() => _loading = false);
    }
  }

  void _logout(BuildContext context) {
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
            : bookingHistory.isEmpty
            ? const Center(child: Text("No approved or rejected history"))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...bookingHistory.map((item) {
                      final statusCode = item['status'].toString();
                      final statusText = _statusText(statusCode);
                      final statusColor = _statusColor(statusCode);
                      final statusIcon = _statusIcon(statusCode);

                      final rejectComment = (item['approver_comment'] ?? '')
                          .toString()
                          .trim();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAE7E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(
                              Icons.location_on,
                              'Room: ${item['room_number']} (Floor ${item['room_location']})',
                            ),
                            const SizedBox(height: 8),
                            _infoRow(
                              Icons.calendar_today,
                              'Date: ${item['room_date'].toString().replaceAll("T", " ").replaceAll("Z", "")}',
                            ),
                            const SizedBox(height: 8),
                            _infoRow(
                              Icons.access_time,
                              'Time: ${_timeSlot(item['room_time'])}',
                            ),
                            const SizedBox(height: 8),
                            _infoRow(Icons.notes, 'Reason: ${item['reason']}'),
                            const SizedBox(height: 8),
                            _infoRow(
                              Icons.person,
                              'Booked by: ${item['booked_by'] ?? 'Unknown'}',
                            ),
                            const SizedBox(height: 8),
                            _infoRow(
                              Icons.verified_user,
                              'Approved by: ${item['approver_name'] ?? 'Unknown'}',
                            ),

                            // ✅ ถ้าโดน Reject และมีเหตุผล ให้แสดง
                            if (statusCode == '3' &&
                                rejectComment.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _infoRow(
                                Icons.feedback,
                                'Reject reason: $rejectComment',
                              ),
                            ],

                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(statusIcon, color: statusColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  statusText,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
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
              icon: Icons.edit_note,
              label: 'Check Status',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckStatusPage()),
                );
              },
            ),
            _BottomNavItem(
              icon: Icons.history,
              label: 'History',
              onTap: () {}, // Already here
            ),
            _BottomNavItem(
              icon: Icons.logout,
              label: 'Logout',
              onTap: () => _logout(context),
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
