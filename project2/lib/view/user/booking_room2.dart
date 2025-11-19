import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project2/view/login.dart';
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

class BookingRoomDetailPage extends StatefulWidget {
  final int roomId; // ใช้ในการ book
  final int roomNumber; // สำหรับแสดงผล
  final String roomName;
  final String roomImage;
  final String timeSlot;

  const BookingRoomDetailPage({
    super.key,
    required this.roomId,
    required this.roomNumber,
    required this.roomName,
    required this.roomImage,
    required this.timeSlot,
  });

  @override
  State<BookingRoomDetailPage> createState() => _BookingRoomDetailPageState();
}

class _BookingRoomDetailPageState extends State<BookingRoomDetailPage> {
  String? selectedReason;
  final TextEditingController otherReasonController = TextEditingController();

  int? userId;

  @override
  void initState() {
    super.initState();
    loadUserId();

    otherReasonController.addListener(() {
      setState(() {});
    });
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('uid');
    });

    print("🔥 Loaded userId = $userId");
  }

  int mapTimeSlotToNumber(String timeSlot) {
    if (timeSlot.contains("8.00")) return 1;
    if (timeSlot.contains("10.00")) return 2;
    if (timeSlot.contains("13.00")) return 3;
    if (timeSlot.contains("15.00")) return 4;
    return 0;
  }

  Future<void> _bookRoom() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID error, please login again.")),
      );
      return;
    }

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
        Uri.parse('http://192.168.1.123:3000/api/book'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'room_id': widget.roomId, // ส่ง room_id ตรง!!! ไม่ผิดแน่นอน
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
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
  void dispose() {
    otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOtherSelected = selectedReason == "Other";

    return Scaffold(
      backgroundColor: SColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "QuickRoom",
          style: TextStyle(
            color: SColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: SColors.primaryRed),
            onPressed: _logout,
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SColors.card,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          widget.roomName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: SColors.text,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SColors.primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.timeSlot,
                            style: const TextStyle(
                              fontSize: 15,
                              color: SColors.primaryRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            widget.roomImage,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Booking Reason:",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: SColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          value: selectedReason,
                          items: const [
                            DropdownMenuItem(
                              value: "Study",
                              child: Text("Study"),
                            ),
                            DropdownMenuItem(
                              value: "Group Meeting",
                              child: Text("Group Meeting"),
                            ),
                            DropdownMenuItem(
                              value: "Project Work",
                              child: Text("Project Work"),
                            ),
                            DropdownMenuItem(
                              value: "Other",
                              child: Text("Other"),
                            ),
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
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: "Please specify your reason",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                        const SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed:
                                selectedReason == null ||
                                    (isOtherSelected &&
                                        otherReasonController.text
                                            .trim()
                                            .isEmpty)
                                ? null
                                : () {
                                    _showConfirmDialog(context);
                                  },
                            child: const Text(
                              "Confirm Booking",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

      // BOTTOM NAV
      bottomNavigationBar: bottomNavBar(context),
    );
  }

  Widget bottomNavBar(BuildContext context) {
    return Container(
      color: SColors.primaryRed,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(Icons.home, "Home", () {
              Navigator.pop(context);
            }),
            navItem(Icons.edit_note, "Status", () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CheckStatusPage()),
              );
            }),
            navItem(Icons.history, "History", () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
