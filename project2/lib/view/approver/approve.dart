import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:project2/view/approver/history_approver.dart';
import 'package:project2/view/approver/home.dart';
import 'package:project2/view/approver/proflie.dart';
import 'package:project2/view/login.dart';

/// ===== Backend base URL =====
/// ใส่ IP/Port ให้ตรงกับเครื่องที่รัน Node.js
const String kBaseUrl = "http://192.168.1.123:3000";

/// ===== Colors =====
class AColors {
  static const bg = Color(0xFFF7F7F9);
  static const primaryRed = Color(0xFF7A2E22);
  static const gold = Color(0xFFCC9A2B);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF2E2E2E);
}

/// ===== Model (จาก DB จริง) =====
class ApproveItem {
  final int id;           // booking_history.id
  final String userName;  // ผู้ขอจอง (u.username)
  final String room;      // "Room 101" ฯลฯ
  final String date;      // เช่น "1 Nov 2025"
  final String time;      // "8:00 AM - 10:00 AM"
  final String reason;    // เหตุผล

  ApproveItem({
    required this.id,
    required this.userName,
    required this.room,
    required this.date,
    required this.time,
    required this.reason,
  });

  factory ApproveItem.fromHistoryJson(Map<String, dynamic> j) {
    return ApproveItem(
      id: j['id'] as int,
      userName: (j['name'] ?? '').toString(),
      room: (j['room'] ?? '').toString(),
      date: (j['date'] ?? '').toString(),
      time: (j['time'] ?? '').toString(),
      reason: (j['reason'] ?? '').toString(),
    );
  }
}

class ApprovePage extends StatefulWidget {
  const ApprovePage({super.key});
  @override
  State<ApprovePage> createState() => _ApprovePageState();
}

class _ApprovePageState extends State<ApprovePage> {
  bool _loading = true;
  String? _error;
  final List<ApproveItem> _items = [];
  final Set<int> _busyIds = {}; // ป้องกันกดซ้ำต่อรายการ
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  /// ดึง "คำขอค้างอนุมัติ" จาก DB
  Future<void> _loadPending() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('$kBaseUrl/api/staff/history');
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('โหลดไม่สำเร็จ (${res.statusCode})');
      }
      final List data = json.decode(res.body) as List;

      // staff/history คืนรายการทั้งหมด → กรองเอา Pending
      final pending = data.where((e) => (e['status'] ?? '') == 'Pending');
      final mapped = pending
          .map((e) => ApproveItem.fromHistoryJson(e as Map<String, dynamic>))
          .toList();

      _items
        ..clear()
        ..addAll(mapped);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// เรียกอนุมัติ/ปฏิเสธจริงไปที่ backend
  Future<void> _submitDecision(
    ApproveItem it,
    String status, {
    String? reason, // ตอนนี้ backend ไม่รับ reason; เก็บไว้แสดง UI
  }) async {
    if (_busyIds.contains(it.id)) return;
    _busyIds.add(it.id);
    setState(() {});

    // ลบแบบ optimistic
    final idx = _items.indexWhere((x) => x.id == it.id);
    ApproveItem? removed;
    if (idx != -1) {
      removed = _items.removeAt(idx);
      setState(() {});
    }

    // 2=approve, 3=reject
    final String statusCode = status == 'approved' ? '2' : '3';
    try {
      final uri = Uri.parse('$kBaseUrl/api/approver/booking/${it.id}');
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': statusCode}),
      );

      if (res.statusCode != 200) {
        // rollback ถ้า fail
        if (removed != null) {
          _items.insert(idx, removed);
        }
        throw Exception('อัปเดตไม่สำเร็จ (${res.statusCode})');
      }

      final msg = status == 'approved'
          ? 'อนุมัติคำขอ #${it.id} เรียบร้อย'
          : 'ปฏิเสธคำขอ #${it.id}'
              '${(reason != null && reason.trim().isNotEmpty) ? ' (เหตุผล: ${reason.trim()})' : ''}';
      _showSnack(msg);
    } catch (e) {
      _showSnack('ผิดพลาด: $e');
    } finally {
      _busyIds.remove(it.id);
      if (mounted) setState(() {});
    }
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
              backgroundColor: AColors.primaryRed,
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

  /// ยืนยันอนุมัติ
  Future<void> _confirmApprove(ApproveItem it) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการอนุมัติ'),
        content: Text('ต้องการอนุมัติคำขอ #${it.id} ใช่ไหม?\n'
            'ห้อง: ${it.room}\nเวลา: ${it.time}\nผู้ขอ: ${it.userName}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
    if (ok == true) await _submitDecision(it, 'approved');
  }

  /// ขอเหตุผลการปฏิเสธ → ส่ง backend เฉพาะ status (ตอนนี้ backend ยังไม่รับ reason)
  Future<void> _promptRejectReason(ApproveItem it) async {
    final ctl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการไม่อนุมัติ'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctl,
            autofocus: true,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'ระบุเหตุผลการปฏิเสธ',
              hintText: 'เช่น ขัดกับตารางใช้งาน / เอกสารไม่ครบ / เวลาซ้ำซ้อน',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'กรุณากรอกเหตุผล';
              }
              if (v.trim().length < 5) {
                return 'กรุณากรอกอย่างน้อย 5 ตัวอักษร';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
            child: const Text('ส่งเหตุผล'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _submitDecision(it, 'rejected', reason: ctl.text);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPending,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: top * 0.1)),
              SliverToBoxAdapter(child: _buildHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      'รายการคำขอ (Pending)',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AColors.primaryRed,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
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
                        OutlinedButton(
                          onPressed: _loadPending,
                          child: const Text('ลองอีกครั้ง'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('ไม่มีรายการค้างอนุมัติ'),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _loadPending,
                          child: const Text('รีโหลด'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      if (i.isOdd) return const SizedBox(height: 12);
                      final idx = i ~/ 2;
                      final it = _items[idx];
                      return _ApproveCard(
                        item: it,
                        busy: _busyIds.contains(it.id),
                        onApprove: () => _confirmApprove(it),
                        onReject: () => _promptRejectReason(it),
                      );
                    }, childCount: _items.length * 2 - 1),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Quick',
                  style: TextStyle(
                    color: AColors.gold,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: 'Room',
                  style: TextStyle(
                    color: AColors.primaryRed,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Ink(
            decoration: const ShapeDecoration(
              color: AColors.card,
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
              icon: const Icon(Icons.logout_rounded, color: AColors.primaryRed),
              onPressed: _confirmLogout,
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
    );
  }

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
        color: AColors.primaryRed,
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
                      break; // หน้านี้
                    case 2:
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );
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
                      Icon(
                        items[i].icon,
                        size: 22,
                        color: active ? AColors.gold : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          color: active ? AColors.gold : Colors.white,
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
}

/// ===== Card แสดงรายการอนุมัติ =====
class _ApproveCard extends StatelessWidget {
  final ApproveItem item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApproveCard({
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: IgnorePointer(
        ignoring: busy,
        child: Container(
          decoration: BoxDecoration(
            color: AColors.card,
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
                  'Order Number : #${item.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text('ผู้ขอ : ${item.userName}', style: const TextStyle(color: AColors.text)),
                const SizedBox(height: 2),
                Text('ห้อง : ${item.room}', style: const TextStyle(color: AColors.text)),
                const SizedBox(height: 2),
                Text('วันที่ : ${item.date}', style: const TextStyle(color: AColors.text)),
                const SizedBox(height: 2),
                Text('เวลา : ${item.time}', style: const TextStyle(color: AColors.text)),
                if (item.reason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('เหตุผล : ${item.reason}',
                      style: TextStyle(color: AColors.text.withOpacity(0.85))),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        onPressed: onApprove,
                        child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE74C3C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        onPressed: onReject,
                        child: const Text('No', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
