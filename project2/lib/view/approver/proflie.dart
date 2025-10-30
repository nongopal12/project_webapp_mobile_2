import 'package:flutter/material.dart';
import 'package:project2/view/approver/history_approver.dart';
import 'package:project2/view/approver/home.dart';
import 'package:project2/view/login.dart';
import 'approve.dart';

/// ========= THEME =========
class PColors {
  static const bg = Color(0xFFF7F7F9);
  static const primaryRed = Color(0xFF7A2E22);
  static const gold = Color(0xFFCC9A2B);
  static const card = Colors.white;
  static const text = Color(0xFF2E2E2E);
}

class ProfileApproverPage extends StatefulWidget {
  const ProfileApproverPage({super.key});

  @override
  State<ProfileApproverPage> createState() => _ProfileApproverPageState();
}

class _ProfileApproverPageState extends State<ProfileApproverPage> {
  int _currentIndex = 3;

  // mock (ต่อ backend ภายหลังได้)
  final String displayName = 'Mr.Chayut Samanupawin';
  final String approverId = '0001';

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: PColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(top: top + 12, bottom: 90),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _profileCard(), // ← ใช้รูปการ์ดจริงจาก assets/profile_photo.png
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// ===== Header: QuickRoom + Logout =====
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              children: const [
                TextSpan(
                  text: 'Quick',
                  style: TextStyle(
                    color: PColors.gold,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: 'Room',
                  style: TextStyle(
                    color: PColors.primaryRed,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Ink(
            decoration: const ShapeDecoration(
              color: PColors.card,
              shape: CircleBorder(),
              shadows: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: PColors.primaryRed),
              tooltip: 'Logout',
              onPressed: _confirmLogout,
            ),
          ),
        ],
      ),
    );
  }

  /// ===== ใช้ภาพการ์ดโปรไฟล์จริง (ไม่สร้างการ์ดใหม่) =====
  Widget _profileCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: PColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/images/Profile_approver.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// ===== Logout confirm =====
  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('ต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  /// ===== Bottom Navigation =====
  Widget _buildBottomBar() {
    const items = [
      _NavSpec('Main', Icons.home_outlined),
      _NavSpec('Approver', Icons.verified_outlined),
      _NavSpec('History', Icons.history),
      _NavSpec('Profile', Icons.person_outline),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: PColors.primaryRed,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final active = _currentIndex == i;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() => _currentIndex = i);
                  switch (i) {
                    case 0:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeApprover()),
                      );
                      break;
                    case 1:
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ApprovePage()),
                      );
                      break;
                    case 2:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryPage(),
                        ),
                      );
                      break;
                    case 3:
                      // current page
                      break;
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].icon,
                        size: 22,
                        color: active ? PColors.gold : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          color: active ? PColors.gold : Colors.white,
                          fontSize: 12.5,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavSpec {
  final String label;
  final IconData icon;
  const _NavSpec(this.label, this.icon);
}
