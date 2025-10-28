import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    // Listen to text field changes for enabling/disabling the button
    otherReasonController.addListener(() {
      setState(() {});
    });
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Booking"),
          content: Text(
              "Are you sure you want to book ${widget.roomName} for ${widget.timeSlot}?"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context); // close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green,
                    content: Text(
                        "Booking confirmed for ${widget.roomName} (${widget.timeSlot})"),
                  ),
                );
                Navigator.pop(context); // back to previous page
              },
              child: const Text("Yes, Book It",
                  style: TextStyle(color: Colors.white)),
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
        title: const Text("Booking Room",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            color: const Color(0xFFF5F5F5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      child: Text("Booking Reason:",
                          style: TextStyle(fontSize: 14)),
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
                            value: "Project Work",
                            child: Text("Project Work")),
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

                    // Only show text field when “Other” is selected
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
