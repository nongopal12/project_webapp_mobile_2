import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project2/view/approver/checkstatus_approver.dart';
import 'package:project2/view/approver/history_approver.dart';
import 'package:project2/view/approver/proflie.dart';
import 'package:project2/view/login.dart';
import 'approve.dart';
import 'proflie.dart';
import 'approve_detail.dart'; // <-- หน้าใหม่ที่เราจะสร้าง
import 'room_browser.dart';

/// ===== Backend base URL =====
const String kBaseUrl = "http://192.168.1.123:3000";

/// ===== THEME (โทนสี QuickRoom) =====
class QColors {
  static const Color bg = Color(0xFFF7F7F9);
  static const Color primaryRed = Color(0xFF7A2E22);
  static const Color gold = Color(0xFFCC9A2B);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF2E2E2E);
  static const Color muted = Color(0xFF8E8E93);
  static const Color free = Color(0xFF2ECC71);
  static const Color pending = Color(0xFFF4B400);
  static const Color reserved = Color(0xFFE74C3C);
  static const Color disabled = Color(0xFFB0B3B8);
}

class BookingItem {
  final int id;            // booking_history.id
  final String userName;   // u.username
  final String room;       // "Room 101" ...
  final String time;       // "8:00 AM - 10:00 AM"
  final String imagePath;  // ชื่อไฟล์รูปจาก DB เช่น "Meeting-RoomA.jpg"

  BookingItem({
    required this.id,
    required this.userName,
    required this.room,
    required this.time,
    required this.imagePath,
  });

  factory BookingItem.fromStaffHistory(Map<String, dynamic> j) {
    return BookingItem(
      id: j['id'] as int,
      userName: (j['name'] ?? '').toString(),
      room: (j['room'] ?? '').toString(),
      time: (j['time'] ?? '').toString(),
      imagePath: (j['image'] ?? '').toString(),   // ✅ มาจาก API ที่เราเพิ่งเพิ่ม
    );
  }
}

/// ====== HOME (Approver) ======
class HomeApprover extends StatefulWidget {
  final String? username; // จะรับจากหน้า login ได้
  const HomeApprover({super.key, this.username});

  @override
  State<HomeApprover> createState() => _HomeApproverState();
}

class _HomeApproverState extends State<HomeApprover> {
  // ======= STATE จาก DB =======
  bool _loading = true;
  String? _error;

  // โปรไฟล์จาก /api/profile/:username
  String _displayName = '';
  String _displayEmail = '';
  String _displayRole = 'Approver';

  // สถิติห้องจาก /api/staff/dashboard
  int _countFree = 0;     // Enable
  int _countPending = 0;  // Pending
  int _countReserved = 0; // Reserved
  int _countDisabled = 0; // Disable

  // รายการคำขอ (Pending) สำหรับลิสต์ด้านล่าง (ดึงจริง)
  final List<BookingItem> _orders = [];

  int _currentIndex = 0;

  // mock กล่องข้อความเดิมไว้เหมือนเดิม
final List<_Msg> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

 Future<void> _loadAll() async {
  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    final username = await _resolveUsername();
    await _fetchProfile(username);
    await _fetchDashboard();
    await _fetchPendingOrders();      // ← เรียกแค่ครั้งเดียวพอ
    await _fetchNotificationMsgs();   // ← โหลดข้อความแจ้งเตือนจริง
  } catch (e) {
    _error = e.toString();
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}




  /// หา username: รับจาก widget หรืออ่านจาก SharedPreferences('username')
  Future<String> _resolveUsername() async {
    if (widget.username != null && widget.username!.trim().isNotEmpty) {
      return widget.username!;
    }
    final sp = await SharedPreferences.getInstance();
    final u = sp.getString('username');
    if (u == null || u.trim().isEmpty) {
      return 'admin';
    }
    return u;
  }

  Future<void> _fetchProfile(String username) async {
    final uri = Uri.parse('$kBaseUrl/api/profile/$username');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('โหลดโปรไฟล์ไม่สำเร็จ (${res.statusCode})');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    _displayName = (data['username'] ?? '').toString();
    _displayEmail = (data['user_email'] ?? '').toString();
    _displayRole = (data['role_name'] ?? 'Approver').toString();
  }

  Future<void> _fetchDashboard() async {
    final uri = Uri.parse('$kBaseUrl/api/staff/dashboard');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('โหลดข้อมูลสถิติห้องไม่สำเร็จ (${res.statusCode})');
    }
    final data = (json.decode(res.body) as Map<String, dynamic>);
    _countFree = int.tryParse('${data['enable_count'] ?? 0}') ?? 0;
    _countPending = int.tryParse('${data['pending_count'] ?? 0}') ?? 0;
    _countReserved = int.tryParse('${data['reserved_count'] ?? 0}') ?? 0;
    _countDisabled = int.tryParse('${data['disabled_count'] ?? 0}') ?? 0;
  }

  /// ดึงคำขอทั้งหมด แล้วกรอง Pending (สถานะ 'Pending')
  Future<void> _fetchPendingOrders() async {
    final uri = Uri.parse('$kBaseUrl/api/staff/history');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('โหลดรายการคำขอไม่สำเร็จ (${res.statusCode})');
    }
    final List data = json.decode(res.body) as List;
    final pending = data.where((e) => (e['status'] ?? '') == 'Pending');
    final list = pending
        .map((e) => BookingItem.fromStaffHistory(e as Map<String, dynamic>))
        .toList();

    _orders
      ..clear()
      ..addAll(list);
  }
Future<void> _fetchNotificationMsgs() async {
  final uri = Uri.parse('$kBaseUrl/api/staff/history');
  final res = await http.get(uri);

  if (res.statusCode != 200) {
    throw Exception('โหลดข้อความแจ้งเตือนไม่สำเร็จ (${res.statusCode})');
  }

  final List data = json.decode(res.body) as List;

  // เอาเฉพาะคำขอที่สถานะ Pending
  final pendingList = data.where((e) => (e['status'] ?? '') == 'Pending');

  final msgs = pendingList.map<_Msg>((e) {
    final id = e['id'];
    final room = (e['room'] ?? '').toString();      // เช่น Room 102
    final timeRange = (e['time'] ?? '').toString(); // เช่น 1:00 PM - 3:00 PM

    // ===== ดึงเวลาจาก room_date =====
    final dateStr = (e['room_date'] ?? '').toString();
    String displayTime = '-';

    // พยายาม parse เป็น DateTime ก่อน (รองรับทั้ง "2025-11-21 18:59:12" และ "2025-11-21T18:59:12Z")
    final dt = DateTime.tryParse(dateStr);
    if (dt != null) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      displayTime = '$hh:$mm';
    } else if (dateStr.length >= 16) {
      // แผนเผื่อ: ถ้า parse ไม่ผ่าน แต่ string ยาวพอ ให้ตัดเอา index 11-16
      displayTime = dateStr.substring(11, 16);
    }

    final orderNo = id is int
        ? 'ORDER${id.toString().padLeft(4, '0')}'
        : 'ORDER$id';

    return _Msg(
      title: 'คำขอจองใหม่',
      body: '$orderNo $room $timeRange',
      time: displayTime,     // << เวลาแสดงตรงนี้
    );
  }).toList();

  _messages
    ..clear()
    ..addAll(msgs);
}


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
                'ข้อความแจ้งเตือน',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),

              // ✅ ถ้าไม่มีคำขอใหม่ ให้แสดงข้อความแจ้ง
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Text('ยังไม่มีคำขอจองใหม่'),
                      )
                    : ListView.separated(
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
        child: RefreshIndicator(
          onRefresh: _loadAll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topInset * 0.1)),
              SliverToBoxAdapter(child: _buildHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text('เกิดข้อผิดพลาด: $_error'),
                        const SizedBox(height: 8),
                        OutlinedButton(onPressed: _loadAll, child: const Text('ลองอีกครั้ง')),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: _buildStatsGrid()),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  sliver: SliverList.separated(
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => OrderCard(
                      item: _orders[i],
                      onGo: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApproveDetailPage(item: _orders[i]),
                          ),
                        ).then((_) => _loadAll()); // กลับมาแล้วรีเฟรช
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            ],
          ),
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
              _logoutButton(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // การ์ดโปรไฟล์ (โชว์ข้อมูลจาก DB)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: QColors.card,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundImage: AssetImage('assets/images/avatar_placeholder.png'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MiniText(_displayName.isEmpty ? '-' : _displayName, bold: true),
                            _MiniText.rich('Email : ', _displayEmail.isEmpty ? '-' : _displayEmail),
                            _MiniText.rich('Role : ', _displayRole),
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
                        BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.mail_outline),
                      color: QColors.primaryRed,
                      onPressed: _openInbox,
                    ),
                  ),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: _badge('${_messages.length > 99 ? '99+' : _messages.length}'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// กล่องสถิติ 2x2 (ใช้ค่าจริงจาก /api/staff/dashboard)
  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          StatTile(
            title: 'Free',
            value: '$_countFree',
            color: QColors.free,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatusRoomPage(status: 'Free')),
              );
            },
          ),
          StatTile(
            title: 'Pending',
            value: '$_countPending',
            color: QColors.pending,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatusRoomPage(status: 'Pending')),
              );
            },
          ),
          StatTile(
            title: 'Reserved',
            value: '$_countReserved',
            color: QColors.reserved,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatusRoomPage(status: 'Reserved')),
              );
            },
          ),
          StatTile(
            title: 'Disabled',
            value: '$_countDisabled',
            color: QColors.disabled,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatusRoomPage(status: 'Disabled')),
              );
            },
          ),
          Align(
  alignment: Alignment.centerRight,
  child: Padding(
    padding: const EdgeInsets.only(top: 10),
    child: SizedBox(
      width: double.infinity, // ✅ เพิ่มความยาวปุ่ม (ปรับตัวเลขได้ตามใจเลย)
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,      // ✅ พื้นหลังปุ่มสีขาว
          foregroundColor: Colors.black87,    // ✅ ตัวอักษร + ไอคอนสีดำ
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          elevation: 0,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoomBrowserPage()),
          );
        },
        icon: const Icon(Icons.meeting_room_outlined),
        label: const Text('Browse Rooms'),
      ),
    ),
  ),
)

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
          BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, -2)),
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
                      break; // หน้า Home
                    case 1:
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ApprovePage()));
                      break;
                    case 2:
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()));
                      break;
                    case 3:
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileApproverPage()),
                      );
                      break;
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].icon, size: 22, color: active ? QColors.gold : Colors.white),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          color: active ? QColors.gold : Colors.white,
                          fontSize: 12.5,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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
        shadows: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: QColors.primaryRed, foregroundColor: Colors.white),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final sp = await SharedPreferences.getInstance();
      await sp.remove('username');

      if (!mounted) return;
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
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}

/// การ์ดสถิติ (กดได้)
class StatTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

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
      width: w,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: QColors.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// การ์ดรายการคำสั่งจอง (แสดงเฉพาะ 4 ฟิลด์ที่ต้องการ)
class OrderCard extends StatelessWidget {
  final BookingItem item;
  final VoidCallback onGo;
  const OrderCard({super.key, required this.item, required this.onGo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order number
            Text(
              'Order Number : #${item.id}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: QColors.text),
            ),
            const SizedBox(height: 8),
            // ห้อง
            Text('ห้อง : ${item.room}', style: const TextStyle(color: QColors.text)),
            const SizedBox(height: 4),
            // เวลา
            Text('เวลา : ${item.time}', style: const TextStyle(color: QColors.text)),
            const SizedBox(height: 4),
            // ชื่อ User
            Text('ผู้ขอ : ${item.userName}', style: const TextStyle(color: QColors.text)),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: QColors.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  elevation: 0,
                ),
                onPressed: onGo,
                child: const Text('Go', style: TextStyle(fontWeight: FontWeight.w700)),
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
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 3))],
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
                      msg.time,  // 👈 ตอนนี้น่าจะแสดงเช่น "18:59"
                      style: const TextStyle(color: QColors.muted, fontSize: 12),
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
