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
  static const Color cardBg = Color(0xFFF2F2F2);
  static const Color pendingColor = Color(0xFFE6D60A); // yellow
  static const Color approvedColor = Color(0xFF4CAF50); // green
  static const Color rejectedColor = Color(0xFFF44336); // red

  // current booking
  final Map<String, String> booking = {
    'name': 'Ronaldo',
    'room': '100',
    'time': '20 Oct 2025 10:00 - 12:00',
    'status': 'Pending',
  };

  //color based on status
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
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
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IconTextRow(
                            icon: Icons.person,
                            text: booking['name']!,
                          ),
                          const SizedBox(height: 6),
                          _IconTextRow(
                            icon: Icons.location_on,
                            text: booking['room']!,
                          ),
                          const SizedBox(height: 6),
                          _IconTextRow(
                            icon: Icons.access_time,
                            text: booking['time']!,
                          ),
                          const SizedBox(height: 6),
                          _IconTextRow(
                            icon: Icons.description,
                            text: 'Work with friend',
                          ),
                          const SizedBox(height: 6),
                          _IconTextRow(icon: Icons.person_outline, text: '_'),
                          const SizedBox(height: 36),
                        ],
                      ),
                      // status badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(booking['status']!),
                            borderRadius: BorderRadius.circular(16),
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
      ),

      // bottom nav
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
}

//  icon + text row
class _IconTextRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconTextRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    const Color brown = Color(0xFF6B2E1E);
    return Row(
      children: [
        Icon(icon, color: brown, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    );
  }
}

// bottom nav item
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

