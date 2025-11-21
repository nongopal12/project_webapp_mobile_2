import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project2/view/login.dart';
import 'history_user.dart';
import 'booking_room.dart';

/// ===== QuickRoom Theme =====
class SColors {
  static const Color bg = Color(0xFFF7F7F9);
  static const Color primaryRed = Color.fromARGB(255, 136, 60, 48);
  static const Color gold = Color(0xFFCC9A2B);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF2E2E2E);
}

class CheckStatusPage extends StatefulWidget {
  const CheckStatusPage({super.key});

  @override
  State<CheckStatusPage> createState() => _CheckStatusPageState();
}

class _CheckStatusPageState extends State<CheckStatusPage> {
  List<dynamic> bookingList = [];
  bool _loading = true;
  final String baseUrl = "http://172.27.13.156:3000";

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('uid') ?? 3;

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/status/$userId'),
      );
      if (response.statusCode == 200) {
        List data = json.decode(response.body);

        // 🔸 Show only Pending (status = 1)
        setState(() {
          bookingList = data
              .where((b) => b['status'].toString() == '1')
              .toList();
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

  Future<void> _refreshStatus() async {
    setState(() {
      _loading = true;
    });
    await _fetchStatus();
  }

  void _logout() async {
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
            onPressed: _logout,
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
          onRefresh: _refreshStatus,
          color: SColors.primaryRed,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : bookingList.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(
                      child: Text(
                        "No pending bookings",
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
                      'Check Pending Bookings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: SColors.text,
                      ),
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
                  'Room ${booking['room_number']}',
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
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      text,
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

          _infoRow(Icons.location_on, 'Floor ${booking['room_location']}'),
          const SizedBox(height: 6),
          _infoRow(
            Icons.calendar_today,
            'Date: ${booking['room_date'].toString().split('T')[0]}',
          ),
          const SizedBox(height: 6),
          _infoRow(
            Icons.access_time,
            'Time: ${_timeSlot(booking['room_time'])}',
          ),
          const SizedBox(height: 6),
          _infoRow(Icons.notes, 'Reason: ${booking['reason']}'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
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
              onTap: () {}, // already here
            ),
            _BottomNavItem(
              icon: Icons.history,
              label: 'History',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
            ),
            _BottomNavItem(icon: Icons.logout, label: 'Logout', onTap: _logout),
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
