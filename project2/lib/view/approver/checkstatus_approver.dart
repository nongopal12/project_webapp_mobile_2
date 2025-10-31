import 'package:flutter/material.dart';
import 'package:project2/view/approver/history_approver.dart';
import 'package:project2/view/approver/proflie.dart';
import 'home.dart';
import 'approve.dart';

/// ===== Colors สำหรับหน้าแสดงสถานะห้อง =====
class QColors {
  static const bg = Color(0xFFF7F7F9);
  static const primaryRed = Color(0xFF7A2E22);
  static const gold = Color(0xFFCC9A2B);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF2E2E2E);

  // ✅ สีสถานะห้อง
  static const free = Color(0xFF2ECC71); // เขียว (ห้องว่าง)
  static const pending = Color(0xFFF1C40F); // เหลือง (รออนุมัติ)
  static const reserved = Color(0xFF3498DB); // น้ำเงิน (จองแล้ว)
  static const disabled = Color(0xFFE74C3C); // แดง (ปิดใช้งาน)
}

/// หน้าแสดงสถานะห้อง (Free / Pending / Reserved / Disabled)
class StatusRoomPage extends StatefulWidget {
  final String status;
  const StatusRoomPage({super.key, required this.status});

  @override
  State<StatusRoomPage> createState() => _StatusRoomPageState();
}

class _StatusRoomPageState extends State<StatusRoomPage> {
  int _currentIndex = 0;

  /// mock room data
  List<Map<String, dynamic>> get _allRooms => [
    {'room': 'ห้อง ที่ 1', 'status': 'Free', 'img': 'assets/images/Meeting-RoomA.jpg'},
    {'room': 'ห้อง ที่ 2', 'status': 'Pending', 'img': 'assets/images/Meeting-Room-B.jpg'},
    {'room': 'ห้อง ที่ 3', 'status': 'Reserved', 'img': 'assets/images/Meeting-RoomC.jpg'},
    {'room': 'ห้อง ที่ 4', 'status': 'Disabled', 'img': 'assets/images/MeetingRoomD.jpg'},
    {'room': 'ห้อง ที่ 5', 'status': 'Free', 'img': 'assets/images/MeetingRoomE.jpg'},
  ];

  Color _statusColor(String s) {
    switch (s) {
      case 'Free':
        return QColors.free;
      case 'Pending':
        return QColors.pending;
      case 'Reserved':
        return QColors.reserved;
      case 'Disabled':
        return QColors.disabled;
      default:
        return QColors.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _allRooms.where((r) => r['status'] == widget.status).toList();

    return Scaffold(
      backgroundColor: QColors.bg,
      appBar: AppBar(
        title: Text(
          'สถานะห้อง : ${widget.status}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: QColors.primaryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: rooms.isEmpty
            ? Center(
                child: Text(
                  'ไม่มีห้องในสถานะ "${widget.status}"',
                  style: TextStyle(
                    color: QColors.text.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: rooms.length,
                itemBuilder: (_, i) {
                  final r = rooms[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              r['img'],
                              width: 90,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['room'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status : ${r['status']}',
                                  style: TextStyle(
                                    color: _statusColor(r['status']),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  /// ===== Bottom Navigation Bar =====
  Widget _buildBottomBar(BuildContext context) {
    final items = [
      _NavSpec('Main', Icons.home_outlined),
      _NavSpec('Approver', Icons.verified_outlined),
      _NavSpec('History', Icons.history),
      _NavSpec('Profile', Icons.person_outline),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: QColors.primaryRed,
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
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );
                      break;
                    case 3:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileApproverPage(),
                        ),
                      );
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
                        color: active ? QColors.gold : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          color: active ? QColors.gold : Colors.white,
                          fontSize: 12.5,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: 0.2,
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
  _NavSpec(this.label, this.icon);
}
