import 'package:flutter/material.dart';
import 'history_user.dart';

class CheckStatusPage extends StatefulWidget {
  const CheckStatusPage({super.key});

  @override
  State<CheckStatusPage> createState() => _CheckStatusPageState();
}

class _CheckStatusPageState extends State<CheckStatusPage> {
  // colors
  static const Color brown = Color(0xFF6B2E1E);
  static const Color pageBg = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFEAE7E6);
  static const Color pendingColor = Color(0xFFE6D60A); // yellow
  static const Color approvedColor = Color(0xFF4CAF50); // green
  static const Color rejectedColor = Color(0xFFF44336); // red

  // booking example
  final Map<String, String> booking = {
    'name': 'Ronaldo',
    'email': 'Ronaldo123@gmail.com',
    'room': 'Room 101',
    'time': '8:00pm - 10:00pm',
    'reason': 'Work with friend',
    'approvedBy': 'Ajarn ABC',
    'status': 'Approved',
  };

  // color based on status
  Color getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return approvedColor;
      case 'Rejected':
        return rejectedColor;
      default:
        return pendingColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Check Booking Status',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // booking card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(Icons.person, 'Name: ${booking['name']}'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.email, 'Email: ${booking['email']}'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.location_on, 'Room: ${booking['room']}'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.access_time, 'Time: ${booking['time']}'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.notes, 'Reason: ${booking['reason']}'),
                    const SizedBox(height: 8),

                    // approved by row
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.brown,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Approved by: ${booking['approvedBy']}',
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusColor(booking['status']!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          booking['status']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // bottom navigation bar
      bottomNavigationBar: Container(
        color: brown,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryPage()),
                  );
                },
              ),
              _BottomNavItem(
                icon: Icons.edit_note,
                label: 'Check Status',
                onTap: () {},
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

// bottom navigation item widget
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
