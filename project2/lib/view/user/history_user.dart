import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project2/view/login.dart';
import 'checkstatus.dart';
import 'booking_room.dart';

/// ===== QuickRoom Theme =====
class SColors {
  static const Color bg = Color(0xFFF7F7F9);
  static const Color primaryRed = Color.fromARGB(255, 136, 60, 48);
  static const Color gold = Color(0xFFCC9A2B);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF2E2E2E);
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> bookingHistory = [];
  bool _loading = true;

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
      String? token = prefs.getString('token');

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

  Future<void> _refreshHistory() async {
    setState(() {
      _loading = true;
    });
    await _fetchHistory();
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
              backgroundColor: SColors.primaryRed,
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
        return Colors.orange;
      case '2':
        return Colors.green;
      case '3':
        return Colors.red;
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
      backgroundColor: SColors.bg, // 🔥 พื้นหลังสีเทาอ่อน
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: 'Quick',
                style: TextStyle(color: SColors.gold),
              ),
              TextSpan(
                text: 'Room',
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
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[300], height: 1),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshHistory,
          color: SColors.primaryRed,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : bookingHistory.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(
                      child: Text(
                        "No approved or rejected history",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const Text(
                      'Booking History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: SColors.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...bookingHistory.map((item) {
                      final statusCode = item['status'].toString();
                      final statusText = _statusText(statusCode);
                      final statusColor = _statusColor(statusCode);
                      final statusIcon = _statusIcon(statusCode);

                      final rejectComment = (item['approver_comment'] ?? '')
                          .toString()
                          .trim();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔥 Header with Status Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Room ${item['room_number']}',
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        statusIcon,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        statusText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            _infoRow(
                              Icons.location_on,
                              'Floor ${item['room_location']}',
                            ),
                            const SizedBox(height: 6),
                            _infoRow(
                              Icons.calendar_today,
                              'Date: ${item['room_date'].toString().split('T')[0]}',
                            ),
                            const SizedBox(height: 6),
                            _infoRow(
                              Icons.access_time,
                              'Time: ${_timeSlot(item['room_time'])}',
                            ),
                            const SizedBox(height: 6),
                            _infoRow(
                              Icons.person,
                              'Booked by: ${item['booked_by'] ?? 'Unknown'}',
                            ),
                            const SizedBox(height: 6),
                            _infoRow(
                              Icons.verified_user,
                              'Approved by: ${item['approver_name'] ?? 'Unknown'}',
                            ),
                            const SizedBox(height: 6),
                            _infoRow(Icons.notes, 'Reason: ${item['reason']}'),

                            // 🔥 Reject reason (เฉพาะ Reject)
                            if (statusCode == '3' && rejectComment.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.feedback,
                                        size: 18,
                                        color: Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Reject reason: $rejectComment",
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
        Icon(icon, color: SColors.primaryRed, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: SColors.text),
          ),
        ),
      ],
    );
  }

  Widget _bottomNavBar() {
    return Container(
      color: SColors.primaryRed, // 🔥 สีแดง
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
                Navigator.pushReplacement(
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
