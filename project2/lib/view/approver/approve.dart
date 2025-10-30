import 'package:flutter/material.dart';
import 'package:project2/view/approver/history_approver.dart';
import 'package:project2/view/approver/home.dart';
import 'package:project2/view/approver/proflie.dart';
import 'package:project2/view/login.dart';

/// ===== Colors =====
class AColors {
  static const bg = Color(0xFFF7F7F9);
  static const primaryRed = Color(0xFF7A2E22);
  static const gold = Color(0xFFCC9A2B);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF2E2E2E);
}

/// ===== Model =====
class ApproveItem {
  final int id;
  final String room;
  final String time;
  ApproveItem({required this.id, required this.room, required this.time});
}

class ApprovePage extends StatefulWidget {
  const ApprovePage({super.key});
  @override
  State<ApprovePage> createState() => _ApprovePageState();
}

class _ApprovePageState extends State<ApprovePage> {
  bool _loading = true;
  final List<ApproveItem> _items = [];
  final Set<int> _busyIds = {}; // ป้องกันกดซ้ำต่อรายการ
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  /// โหลด mock data (ไม่เรียก API)
  Future<void> _loadPending() async {
    setState(() => _loading = true);
    await Future<void>.delayed(
      const Duration(milliseconds: 400),
    ); // เอฟเฟกต์โหลดนิดหน่อย
    final mock = List.generate(
      8,
      (i) => ApproveItem(
        id: 1001 + i,
        room: 'R-${(i % 4) + 1}0${(i % 3) + 1}',
        time:
            '10:${(i * 7 % 60).toString().padLeft(2, '0')} - 11:${((i * 7 + 45) % 60).toString().padLeft(2, '0')}',
      ),
    );
    _items
      ..clear()
      ..addAll(mock);
    if (mounted) setState(() => _loading = false);
  }

  /// "ส่งผล" แบบ local: แค่ลบออก + แจ้งเตือน (ไม่เรียกเซิร์ฟเวอร์)
  Future<void> _submitDecision(
    ApproveItem it,
    String status, {
    String? reason,
  }) async {
    if (_busyIds.contains(it.id)) return;
    _busyIds.add(it.id);
    setState(() {});

    final idx = _items.indexWhere((x) => x.id == it.id);
    if (idx != -1) {
      _items.removeAt(idx); // ลบแบบ optimistic
      setState(() {});
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));
    _busyIds.remove(it.id);
    if (!mounted) return;

    final msg = status == 'approved'
        ? 'อนุมัติ ORDER${it.id.toString().padLeft(4, '0')} เรียบร้อย'
        : 'ปฏิเสธ ORDER${it.id.toString().padLeft(4, '0')}${(reason != null && reason.trim().isNotEmpty) ? ' (เหตุผล: ${reason.trim()})' : ''}';
    _showSnack(msg);
    setState(() {});
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
        content: Text(
          'ต้องการอนุมัติ ORDER${it.id.toString().padLeft(4, '0')} ใช่ไหม?',
        ),
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

  /// ขอเหตุผลการปฏิเสธ แล้วค่อย "บันทึก" แบบ local
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
                      'รายการคำขอ',
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
                          child: const Text('ลองโหลดอีกครั้ง'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // ใช้ SliverList ปกติ (SliverList.separated ไม่มีใน Flutter มาตรฐาน)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      // แทรกช่องว่างคั่นรายการ
                      if (i.isOdd) return const SizedBox(height: 12);
                      final index = i ~/ 2;
                      final it = _items[index];
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
                        color: active ? AColors.gold : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          color: active ? AColors.gold : Colors.white,
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

/// ===== Item Card =====
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
                  'Order Number : ORDER${item.id.toString().padLeft(4, '0')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'จองห้อง ${item.room}',
                        style: const TextStyle(color: AColors.text),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'เวลา : ${item.time}',
                      style: const TextStyle(color: AColors.text),
                    ),
                  ],
                ),
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
                        child: const Text(
                          'Yes',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
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
                        child: const Text(
                          'No',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
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
