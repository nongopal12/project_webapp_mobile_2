import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project2/view/approver/history_approver.dart';
import 'package:project2/view/approver/home.dart';
import 'package:project2/view/approver/proflie.dart';
import 'package:project2/view/login.dart';

const String kBaseUrl = "http://192.168.1.112:3000";

class AColors {
  static const bg = Color(0xFFF7F7F9);
  static const primaryRed = Color(0xFF7A2E22);
  static const gold = Color(0xFFCC9A2B);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF2E2E2E);
}

class ApproveItem {
  final int id;
  final String userName;
  final String room;
  final String date;
  final String time;
  final String reason;

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
  final Set<int> _busyIds = {};
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('$kBaseUrl/api/staff/history');
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Failed to load data (${res.statusCode})');
      }

      final List data = json.decode(res.body) as List;
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

  // ==========================================================
  // 🔥 ฟังก์ชันใหม่: ส่ง approver_id + reason เหมือน ApproveDetailPage
  // ==========================================================
  Future<void> _submitDecision(
    ApproveItem it,
    String status, {
    String? reason,
  }) async {
    if (_busyIds.contains(it.id)) return;
    _busyIds.add(it.id);
    setState(() {});

    final idx = _items.indexWhere((x) => x.id == it.id);
    ApproveItem? removed;
    if (idx != -1) {
      removed = _items.removeAt(idx);
      setState(() {});
    }

    final String statusCode = status == 'approved' ? '2' : '3';

    try {
      final prefs = await SharedPreferences.getInstance();
      final approverId = prefs.getInt("uid");

      if (approverId == null) {
        throw Exception("Approver ID missing.");
      }

      final uri = Uri.parse('$kBaseUrl/api/approver/booking/${it.id}');

      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': statusCode,
          'approver_id': approverId,
          'reject_reason': reason ?? "",
        }),
      );

      if (res.statusCode != 200) {
        if (removed != null) _items.insert(idx, removed);
        throw Exception('Update failed (${res.statusCode})');
      }

      final msg = status == 'approved'
          ? 'Request #${it.id} has been approved.'
          : 'Request #${it.id} has been rejected'
                '${(reason != null && reason.trim().isNotEmpty) ? ' (Reason: ${reason.trim()})' : ''}';

      _showSnack(msg);
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      _busyIds.remove(it.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _confirmApprove(ApproveItem it) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: Text(
          'Do you want to approve request #${it.id}?\nRoom: ${it.room}\nTime: ${it.time}\nRequested by: ${it.userName}',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (ok == true) await _submitDecision(it, 'approved');
  }

  Future<void> _promptRejectReason(ApproveItem it) async {
    final ctl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctl,
            autofocus: true,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Rejection Reason',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter a reason';
              if (v.trim().length < 3) return 'At least 3 characters';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
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
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _submitDecision(it, 'rejected', reason: ctl.text.trim());
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

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      'Pending Requests',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AColors.primaryRed,
                      ),
                    ),
                  ),
                ),
              ),

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
                        Text('Error: $_error'),
                        OutlinedButton(
                          onPressed: _loadPending,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_items.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No pending requests')),
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
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
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
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final active = _currentIndex == i;
            return Expanded(
              child: InkWell(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i].icon,
                      color: active ? AColors.gold : Colors.white,
                    ),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        color: active ? AColors.gold : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

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
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Number: #${item.id}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),
            Text("Requested by: ${item.userName}"),
            Text("Room: ${item.room}"),
            Text("Date: ${item.date}"),
            Text("Time: ${item.time}"),

            if (item.reason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text("Reason: ${item.reason}"),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onApprove,
                    child: const Text("Approve"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onReject,
                    child: const Text("Reject"),
                  ),
                ),
              ],
            ),
          ],
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
