import 'package:flutter/material.dart';
import 'package:project2/view/login.dart';
import 'checkstatus.dart';
import 'booking_room.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

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

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFF4CAF50);
      case 'Rejected':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFFE6D60A);
    }
  }

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

              ...bookingHistory.map((item) {
                final statusColor = _statusColor(item['status']!);
                IconData statusIcon;
                String statusLabel;

                if (item['status'] == 'Approved') {
                  statusIcon = Icons.check_circle_outline;
                  statusLabel = 'Approved by: ${item['approvedBy']}';
                } else if (item['status'] == 'Rejected') {
                  statusIcon = Icons.cancel_outlined;
                  statusLabel = 'Rejected by: ${item['approvedBy']}';
                } else {
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

                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              }).toList(),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Container(
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
              _BottomNavItem(
                icon: Icons.logout,
                label: 'Logout',
                onTap: () => _logout(context),
              ),
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
