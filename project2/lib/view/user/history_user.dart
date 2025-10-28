import 'package:flutter/material.dart';
import 'checkstatus.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> bookingHistory = [
      {
        "name": "Ronaldo",
        "email": "Ronaldo123@gmail.com",
        "room": "Room 101",
        "time": "8:00pm - 10:00pm",
        "reason": "Work with friend",
        "approvedBy": "Ajarn ABC",
        "status": "Approved",
      },
      {
        "name": "Ronaldo",
        "email": "Ronaldo123@gmail.com",
        "room": "Room 103",
        "time": "10:00pm - 12:00pm",
        "reason": "Work with friend",
        "approvedBy": "Ajarn ABC",
        "status": "Rejected",
      },
      {
        "name": "Ronaldo",
        "email": "Ronaldo123@gmail.com",
        "room": "Room 102",
        "time": "8:00pm - 10:00pm",
        "reason": "Work with friend",
        "approvedBy": "_",
        "status": "Pending",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking History',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              //  bookings
              ...bookingHistory.map((item) {
                Color statusColor;
                IconData statusIcon;
                String statusLabel;

                if (item['status'] == 'Approved') {
                  statusColor = const Color(0xFF4CAF50); // green
                  statusIcon = Icons.check_circle_outline;
                  statusLabel = 'Approved by: ${item['approvedBy']}';
                } else if (item['status'] == 'Rejected') {
                  statusColor = const Color(0xFFF44336); // red
                  statusIcon = Icons.cancel_outlined;
                  statusLabel = 'Rejected by: ${item['approvedBy']}';
                } else {
                  statusColor = const Color(0xFFE6D60A); // yellow

                  statusIcon = Icons.remove_circle_outline;

                  statusLabel = 'Approved by: _';
                }

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
                      _infoRow(Icons.person, 'Name: ${item['name']}'),
                      const SizedBox(height: 8),
                      _infoRow(Icons.email, 'Email: ${item['email']}'),
                      const SizedBox(height: 8),
                      _infoRow(Icons.location_on, 'Room: ${item['room']}'),
                      const SizedBox(height: 8),
                      _infoRow(Icons.access_time, 'Time: ${item['time']}'),
                      const SizedBox(height: 8),
                      _infoRow(Icons.notes, 'Reason: ${item['reason']}'),
                      const SizedBox(height: 8),

                      // Approved or Rejected by row
                      Row(
                        children: [
                          Icon(
                            statusIcon,
                            color: item['status'] == 'Approved'
                                ? Colors.green
                                : item['status'] == 'Rejected'
                                ? Colors.red
                                : Colors.brown,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Status Button
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
                            item['status']!,
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
              }),
            ],
          ),
        ),
      ),

      // bottom nav
      bottomNavigationBar: Container(
        color: const Color(0xFF6B2E1E),
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(icon: Icons.home, label: 'HOME', onTap: () {}),
              _BottomNavItem(
                icon: Icons.history,
                label: 'History',
                onTap: () {},
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
              _BottomNavItem(icon: Icons.logout, label: 'Logout', onTap: () {}),
            ],
          ),
        ),
      ),
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
}

// bottom nav item widget
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

