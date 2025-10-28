import 'package:flutter/material.dart';
import 'checkstatus.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> bookingHistory = [
      {
        "name": "Ronaldo",
        "room": "Room 100",
        "date": "28 Oct 2025 8:00am - 10.00am",
        "purpose": "Work with friend",
        "lecturer": "Ajarn abc",
        "status": "Pending",
      },
      {
        "name": "Ronaldo",
        "room": "Room 101",
        "date": "28 Oct 2025 10:00am - 12.00pm",
        "purpose": "Study",
        "lecturer": "Ajarn xyz",
        "status": "Approved",
      },
      {
        "name": "Ronaldo",
        "room": "Room 102",
        "date": "28 Oct 2025 1:00pm - 3.00pm",
        "purpose": "Group meeting",
        "lecturer": "Ajarn abc",
        "status": "Rejected",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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

                    // Booking
                    ...bookingHistory.map((item) {
                      Color statusColor;
                      if (item['status'] == 'Approved') {
                        statusColor = Colors.green;
                      } else if (item['status'] == 'Pending') {
                        statusColor = Colors.orange;
                      } else {
                        statusColor = Colors.red;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(Icons.person, item['name']!),
                            const SizedBox(height: 6),
                            _infoRow(Icons.location_on, item['room']!),
                            const SizedBox(height: 6),
                            _infoRow(Icons.access_time, item['date']!),
                            const SizedBox(height: 6),
                            _infoRow(Icons.assignment, item['purpose']!),
                            const SizedBox(height: 6),
                            _infoRow(Icons.person_outline, item['lecturer']!),
                            const SizedBox(height: 10),

                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(8),
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
          ],
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
                onTap: () {
                  // here
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
              _BottomNavItem(icon: Icons.logout, label: 'Logout', onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }

  //  row for icons and text
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.brown, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
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
