import 'package:flutter/material.dart';
import 'package:project2/view/approver/checkstatus_approver.dart';
import 'package:project2/view/approver/history_approver.dart';
import 'package:project2/view/approver/proflie.dart';
import 'package:project2/view/login.dart';
import 'approve.dart';
import 'proflie.dart';

/// ===== THEME (โทนสี QuickRoom) =====
class QColors {
  static const Color bg = Color(0xFFF7F7F9); // ขาวนวล 60%
  static const Color primaryRed = Color(0xFF7A2E22); // แดงอิฐ 30%
  static const Color gold = Color(0xFFCC9A2B); // ทอง 10%
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF2E2E2E);
  static const Color muted = Color(0xFF8E8E93);
  static const Color free = Color(0xFF2ECC71);
  static const Color pending = Color(0xFFF4B400);
  static const Color reserved = Color(0xFFE74C3C);
  static const Color disabled = Color(0xFFB0B3B8);
}

/// ===== MODEL จำลองข้อมูล =====
class OrderItem {
  final String orderNo;
  final String roomText;
  final String timeText;
  OrderItem({
    required this.orderNo,
    required this.roomText,
    required this.timeText,
  });
}

/// ====== HOME (Approver) ======
class HomeApprover extends StatefulWidget {
  const HomeApprover({super.key});

  @override
  State<HomeApprover> createState() => _HomeApproverState();
}

class _HomeApproverState extends State<HomeApprover> {
  // สมมุติข้อมูลตัวอย่าง
  final List<OrderItem> _orders = [
    OrderItem(
      orderNo: 'ORDER0001',
      roomText: 'จองห้อง ที่10',
      timeText: 'เวลา : 12.00',
    ),
    OrderItem(
      orderNo: 'ORDER0002',
      roomText: 'จองห้อง ที่10',
      timeText: 'เวลา : 12.00',
    ),
    OrderItem(
      orderNo: 'ORDER0003',
      roomText: 'จองห้อง ที่12',
      timeText: 'เวลา : 14.30',
    ),
  ];

  int _currentIndex = 0;

  // ตัวอย่างข้อความ (mock)
  final List<_Msg> _messages = [
    _Msg(
      title: 'คำขอจองใหม่',
      body: 'ORDER0005 ห้อง A102 เวลา 09:00-11:00',
      time: '10:21',
    ),
    _Msg(
      title: 'แจ้งเตือนระบบ',
      body: 'มีคำขอค้างอนุมัติ 2 รายการ',
      time: '09:55',
    ),
    _Msg(
      title: 'สถานะคำขอ',
      body: 'ORDER0003 ผู้จองยกเลิกแล้ว',
      time: 'เมื่อวาน',
    ),
    _Msg(
      title: 'แจ้งปิดห้อง',
      body: 'ห้อง C310 ปิดซ่อม 2 ชม.',
      time: 'เมื่อวาน',
    ),
  ];

  void _openInbox() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ข้อความ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: _messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _MessageTile(msg: _messages[i]),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: QColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topInset * 0.1)),
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverToBoxAdapter(child: _buildStatsGrid()),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverList.separated(
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => OrderCard(
                  item: _orders[i],
                  onGo: () {
                    // ✅ กด GO แล้วพาไปหน้า ApprovePage
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ApprovePage()),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 88),
            ), // เว้นให้ Bottom bar
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// ส่วนหัว QuickRoom + โปรไฟล์ + ปุ่ม Logout
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              // โลโก้ชื่อแอป
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Quick',
                      style: TextStyle(
                        color: QColors.gold,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    TextSpan(
                      text: 'Room',
                      style: TextStyle(
                        color: QColors.primaryRed,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // ปุ่ม Logout วงกลม
              _logoutButton(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // การ์ดโปรไฟล์สั้น ๆ
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: QColors.card,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        // ใช้ไฟล์ png ที่มีในโปรเจกต์
                        backgroundImage: AssetImage(
                          'assets/avatar_placeholder.png',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _MiniText('Mr.Chayut Samanupawin', bold: true),
                            _MiniText.rich('Status : ', 'Normal'),
                            _MiniText('ID : 00001'),
                            _MiniText('Position : Approver'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ปุ่มจดหมายพร้อม badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: QColors.card,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.mail_outline),
                      color: QColors.primaryRed,
                      onPressed: _openInbox, // <- เรียกฟังก์ชันเปิด POP-UP
                    ),
                  ),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: _badge(
                      '${_messages.length > 99 ? '99+' : _messages.length}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// กล่องสถิติ 2 แถว 2 คอลัมน์
  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          StatTile(
            title: 'Free',
            value: '6',
            color: QColors.free,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatusRoomPage(status: 'Free'),
                ),
              );
            },
          ),
          StatTile(
            title: 'Pending',
            value: '2',
            color: QColors.pending,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatusRoomPage(status: 'Pending'),
                ),
              );
            },
          ),
          StatTile(
            title: 'Reserved',
            value: '1',
            color: QColors.reserved,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatusRoomPage(status: 'Reserved'),
                ),
              );
            },
          ),
          StatTile(
            title: 'Disabled',
            value: '1',
            color: QColors.disabled,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatusRoomPage(status: 'Disabled'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation (Main / Approver / History / Profile)
  Widget _buildBottomBar() {
    final items = [
      _NavSpec('Main', Icons.home_outlined),
      _NavSpec('Approver', Icons.verified_outlined),
      _NavSpec('History', Icons.history),
      _NavSpec('Profile', Icons.person_outline),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: QColors.primaryRed,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
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
                      // หน้า Home
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

  /// ===== Widgets ย่อย =====
  Widget _logoutButton() {
    return Ink(
      decoration: const ShapeDecoration(
        color: QColors.card,
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
        icon: const Icon(Icons.logout_rounded),
        color: QColors.primaryRed,
        tooltip: 'Logout',
        onPressed: _confirmLogout,
      ),
    );
  }

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
              backgroundColor: QColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );

    if (ok == true) {
      // TODO: เคลียร์ token/session ถ้ามี
      if (!mounted) return;
      // พาไปหน้า Login และล้าง back stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: QColors.gold,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// การ์ดแสดงสถิติห้อง
/// การ์ดแสดงสถิติห้อง (กดได้)
class StatTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap; // <-- เพิ่ม

  const StatTile({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2;
    return SizedBox(
      width: w, // 2 คอลัมน์
      child: InkWell(
        onTap: onTap, // <-- กดแล้วเรียก onTap
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: QColors.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// การ์ดรายการคำสั่งจอง
class OrderCard extends StatelessWidget {
  final OrderItem item;
  final VoidCallback onGo;
  const OrderCard({super.key, required this.item, required this.onGo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Number : ${item.orderNo}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: QColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.roomText,
                    style: const TextStyle(color: QColors.text),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item.timeText,
                  style: const TextStyle(color: QColors.text),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: QColors.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
                onPressed: onGo,
                child: const Text(
                  'Go',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ข้อความย่อยสำหรับการ์ดโปรไฟล์
class _MiniText extends StatelessWidget {
  final String text;
  final bool bold;
  const _MiniText(this.text, {this.bold = false});

  const _MiniText.rich(String lead, String tail, {Color? color2})
    : text = '$lead$tail',
      bold = false;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12.5,
        color: QColors.text.withOpacity(0.88),
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _NavSpec {
  final String label;
  final IconData icon;
  _NavSpec(this.label, this.icon);
}

class _Msg {
  final String title;
  final String body;
  final String time;
  _Msg({required this.title, required this.body, required this.time});
}

class _MessageTile extends StatelessWidget {
  final _Msg msg;
  const _MessageTile({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mail_outline, color: QColors.primaryRed),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        msg.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      msg.time,
                      style: const TextStyle(
                        color: QColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(msg.body, style: const TextStyle(color: QColors.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
