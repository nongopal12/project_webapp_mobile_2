import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project2/view/login.dart';
import 'package:project2/view/user/booking_room2.dart';
import 'history_user.dart';
import 'checkstatus.dart';

/// ===== QuickRoom Theme =====
class SColors {
  static const Color bg = Color(0xFFF7F7F9);
  static const Color primaryRed = Color.fromARGB(255, 136, 60, 48);
  static const Color gold = Color(0xFFCC9A2B);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF2E2E2E);
}

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  List<dynamic> roomList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  Future<void> fetchRooms() async {
    try {
      final response = await http.get(
        Uri.parse('http://172.27.13.156:3000/api/rooms'),
      );
      if (response.statusCode == 200) {
        setState(() {
          roomList = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load rooms');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading rooms: $e')));
    }
  }

  Future<void> _refreshRooms() async {
    setState(() {
      isLoading = true;
    });
    await fetchRooms();
  }

  String statusText(int value) {
    switch (value) {
      case 1:
        return "Available";
      case 2:
        return "Pending";
      case 3:
        return "Reserved";
      case 4:
        return "Disable";
      case 5:
        return "Not Available";
      default:
        return "Unknown";
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Available":
        return Colors.green;
      case "Pending":
        return Colors.amber[700]!;
      case "Reserved":
        return Colors.red;
      case "Disable":
        return Colors.grey;
      case "Not Available":
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  bool isPastTime(String timeRange) {
    final now = DateTime.now();
    try {
      final parts = timeRange.split('-');
      if (parts.length != 2) return false;

      DateTime parsePart(String s) {
        final t = s.trim();
        final hm = t.split('.');
        final h = int.parse(hm[0]);
        final m = (hm.length > 1) ? int.parse(hm[1]) : 0;
        return DateTime(now.year, now.month, now.day, h, m);
      }

      final end = parsePart(parts[1]);
      return now.isAfter(end);
    } catch (_) {
      return false;
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
              backgroundColor: SColors.primaryRed,
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

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDate =
        "${today.day.toString().padLeft(2, '0')} ${_monthName(today.month)} ${today.year}";

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
          onRefresh: _refreshRooms,
          color: SColors.primaryRed,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Room list",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: SColors.text,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...roomList.map((room) => _buildRoomCard(context, room)),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildRoomCard(BuildContext context, dynamic room) {
    final slots = [
      {"time": "8.00 - 10.00", "db": room['room_8AM']},
      {"time": "10.00 - 12.00", "db": room['room_10AM']},
      {"time": "13.00 - 15.00", "db": room['room_1PM']},
      {"time": "15.00 - 17.00", "db": room['room_3PM']},
    ];

    final slotList = slots.map((slot) {
      String status = statusText(slot['db']);
      return {"time": slot['time'], "status": status};
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              'assets/images/${room['room_img']}',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Room ${room['room_number']} (For ${room['room_capacity']} people)",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: SColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "Floor: ${room['room_location']}",
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Column(
                  children: slotList.map<Widget>((slot) {
                    final statusColor = getStatusColor(slot['status']);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            slot['time'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: SColors.text,
                            ),
                          ),

                          /// กดจอง
                          GestureDetector(
                            onTap: slot['status'] == "Available"
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookingRoomDetailPage(
                                          roomId: room['room_id'],
                                          roomNumber: room['room_number'],
                                          roomName:
                                              "Room ${room['room_number']} (For ${room['room_capacity']} people)",
                                          roomImage:
                                              'assets/images/${room['room_img']}',
                                          timeSlot: slot['time'],
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                slot['status'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      color: SColors.primaryRed,
      padding: const EdgeInsets.only(top: 6, bottom: 6),
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
