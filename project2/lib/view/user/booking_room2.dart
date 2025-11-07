import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project2/view/login.dart';
import 'package:project2/view/user/booking_room.dart';
import 'history_user.dart';
import 'checkstatus.dart';

class BookingRoomDetailPage extends StatefulWidget {
  final String roomName;
  final String timeSlot;
  final String image;

  const BookingRoomDetailPage({
    super.key,
    required this.roomName,
    required this.timeSlot,
    required this.image,
  });

  @override
  State<BookingRoomDetailPage> createState() => _BookingRoomDetailPageState();
}

class _BookingRoomDetailPageState extends State<BookingRoomDetailPage> {
  String? selectedReason;
  final TextEditingController otherReasonController = TextEditingController();
  final int userId = 3; // Temporary user ID for now

  @override
  void initState() {
    super.initState();
    otherReasonController.addListener(() {
      setState(() {});
    });
  }

  // Convert readable time slot string to numeric slot for DB
  int mapTimeSlotToNumber(String timeSlot) {
    if (timeSlot.contains("8.00")) return 1;
    if (timeSlot.contains("10.00")) return 2;
    if (timeSlot.contains("13.00")) return 3;
    if (timeSlot.contains("15.00")) return 4;
    return 0;
  }

  Future<void> _bookRoom() async {
    String reasonText = selectedReason == "Other"
        ? otherReasonController.text.trim()
        : selectedReason ?? "";

    if (reasonText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select or enter a reason")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://172.27.11.178:3000/api/book'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'room_id': _extractRoomNumber(widget.roomName),
          'time_slot': mapTimeSlotToNumber(widget.timeSlot),
          'reason': reasonText,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Booking request submitted successfully!'),
          ),
        );

        // Redirect to CheckStatus page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CheckStatusPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  int _extractRoomNumber(String roomName) {
    final regex = RegExp(r'Room\s(\d+)');
    final match = regex.firstMatch(roomName);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    return 0;
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

  void _showConfirmDialog(BuildContext context) {
    String reasonText = selectedReason == "Other"
        ? otherReasonController.text.trim()
        : selectedReason ?? "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Booking"),
          content: Text(
            "Are you sure you want to book ${widget.roomName} for ${widget.timeSlot}?\n\nReason: $reasonText",
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _bookRoom();
              },
              child: const Text(
                "Yes, Book It",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOtherSelected = selectedReason == "Other";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B2E1E),
        title: const Text(
          "Booking Room",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            color: const Color(0xFFF5F5F5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${widget.roomName} (${widget.timeSlot})",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(widget.image,
                          height: 150, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Booking Reason:",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      value: selectedReason,
                      items: const [
                        DropdownMenuItem(
                            value: "Study", child: Text("Study")),
                        DropdownMenuItem(
                            value: "Group Meeting",
                            child: Text("Group Meeting")),
                        DropdownMenuItem(
                            value: "Project Work", child: Text("Project Work")),
                        DropdownMenuItem(value: "Other", child: Text("Other")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value;
                          if (value != "Other") {
                            otherReasonController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    if (isOtherSelected)
                      TextField(
                        controller: otherReasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: "Please specify your reason",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: selectedReason == null ||
                              (isOtherSelected &&
                                  otherReasonController.text.trim().isEmpty)
                          ? null
                          : () {
                              _showConfirmDialog(context);
                            },
                      child: const Text("Confirm Booking",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
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
