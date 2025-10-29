import 'package:flutter/material.dart';
import 'package:project2/view/user/booking_room2.dart';
import 'history_user.dart';
import 'checkstatus.dart';
import '../login.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _BookingRoomPageState();
}

class _BookingRoomPageState extends State<UserHomePage> {
  // Mock data (ready for API connection later)
  final List<Map<String, dynamic>> roomList = [
    {
      "roomName": "Room 100 (For 4 people)",
      "image": "assets/images/Meeting-Room-B.jpg",
      "slots": [
        {"time": "8.00 - 10.00", "status": "Not Available"},
        {"time": "10.00 - 12.00", "status": "Available"},
        {"time": "13.00 - 15.00", "status": "Pending"},
        {"time": "15.00 - 17.00", "status": "Reserved"},
      ],
    },
    {
      "roomName": "Room 101 (For 4 people)",
      "image": "assets/images/Meeting-RoomA.jpg",
      "slots": [
        {"time": "8.00 - 10.00", "status": "Not Available"},
        {"time": "10.00 - 12.00", "status": "Pending"},
        {"time": "13.00 - 15.00", "status": "Available"},
        {"time": "15.00 - 17.00", "status": "Reserved"},
      ],
    },
    {
      "roomName": "Room 102 (For 6 people)",
      "image": "assets/images/Meeting-RoomC.jpg",
      "slots": [
        {"time": "8.00 - 10.00", "status": "Disable"},
        {"time": "10.00 - 12.00", "status": "Disable"},
        {"time": "13.00 - 15.00", "status": "Disable"},
        {"time": "15.00 - 17.00", "status": "Disable"},
      ],
    },
    {
      "roomName": "Room 103 (For 8 people)",
      "image": "assets/images/Meeting-RoomG.jpg",
      "slots": [
        {"time": "8.00 - 10.00", "status": "Not Available"},
        {"time": "10.00 - 12.00", "status": "Pending"},
        {"time": "13.00 - 15.00", "status": "Reserved"},
        {"time": "15.00 - 17.00", "status": "Available"},
      ],
    },
  ];

  Color getStatusColor(String status) {
    switch (status) {
      case "Available":
        return Colors.green;
      case "Pending":
        return Colors.amber[700]!;
      case "Reserved":
        return Colors.orange;
      case "Not Available":
        return Colors.red;
      case "Disable":
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDate =
        "${today.day.toString().padLeft(2, '0')} ${_monthName(today.month)} ${today.year}";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B2E1E),
        title: const Text(
          'QuickRoom',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Row(
                children: [
                  const Text(
                    "Room list",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formattedDate,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...roomList.map((room) => _buildRoomCard(context, room)).toList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildRoomCard(BuildContext context, Map<String, dynamic> room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                room['image'],
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              room['roomName'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: room['slots'].map<Widget>((slot) {
                final statusColor = getStatusColor(slot['status']);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(slot['time'], style: const TextStyle(fontSize: 14)),
                      GestureDetector(
                        onTap: slot['status'] == "Available"
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingRoomDetailPage(
                                      roomName: room['roomName'],
                                      timeSlot: slot['time'],
                                      image: room['image'],
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            slot['status'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
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
    );
  }

  String _monthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      color: const Color(0xFF6B2E1E),
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
              icon: Icons.history,
              label: 'History',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
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
              icon: Icons.logout,
              label: 'Logout',
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
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
