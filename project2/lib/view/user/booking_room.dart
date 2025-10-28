import 'package:flutter/material.dart';
import 'package:project2/view/user/booking_room2.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _BookingRoomPageState();
}

class _BookingRoomPageState extends State<UserHomePage> {
  // Mock data (ready to replace with API later)
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
        return Colors.yellow[700]!;
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
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              children: [
                const Text("Room list",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Text(formattedDate,
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 16),
            ...roomList.map((room) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(room['image'],
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 8),
                      Text(room['roomName'],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Column(
                        children: room['slots'].map<Widget>((slot) {
                          final statusColor = getStatusColor(slot['status']);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(slot['time'],
                                  style: const TextStyle(fontSize: 14)),
                              GestureDetector(
                                onTap: slot['status'] == "Available"
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                BookingRoomDetailPage(
                                                    roomName: room['roomName'],
                                                    timeSlot: slot['time'],
                                                    image: room['image']),
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
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  String _monthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  // ต้องแก้ให้ปุ่มกดได้ กด log out แล้ว กลับไปหน้า log in
  Widget _buildBottomNavBar(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xFF6B2E1E),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomIcon(Icons.home, "HOME"),
            _bottomIcon(Icons.history, "History"),
            _bottomIcon(Icons.edit_note, "Check Status"),
            _bottomIcon(Icons.logout, "Logout"),
          ],
        ),
      ),
    );
  }

  Widget _bottomIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

