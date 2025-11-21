import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:project2/view/login.dart';
import 'package:project2/view/approver/proflie.dart';
import 'approve.dart';
import 'home.dart';

/// ใช้สีเดียวกับหน้า MainApprover
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

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime selectedDate = DateTime.now();
  List<dynamic> historyList = [];
  bool isLoading = true;

  final String baseUrl = "http://172.27.13.156:3000";

  int _toIntStatus(dynamic v) =>
      (v is int) ? v : (int.tryParse(v?.toString() ?? '') ?? 0);

  /// Filter: only Approved (2) and Rejected (3)
  List<dynamic> get visibleHistory => historyList.where((h) {
    final s = _toIntStatus(h['status']);
    return s == 2 || s == 3;
  }).toList();

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      final dateStr =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      final url = Uri.parse(
        '$baseUrl/api/history',
      ).replace(queryParameters: {'date': dateStr});

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() {
          historyList = data;
          isLoading = false;
        });
      } else {
        throw Exception("Server Error ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching history: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: QColors.primaryRed,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        isLoading = true;
      });
      fetchHistory();
    }
  }

  String _displayDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${d.day} ${m[d.month - 1]} ${d.year}";
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: QColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (ok == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),

            _dateSelector(),

            const SizedBox(height: 6),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : visibleHistory.isEmpty
                  ? const Center(child: Text("No history found"))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (_, i) =>
                          HistoryCard(item: visibleHistory[i]),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: visibleHistory.length,
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  /// -------- HEADER --------
  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      width: double.infinity,
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "Quick",
                  style: TextStyle(
                    color: QColors.gold,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: "Room",
                  style: TextStyle(
                    color: QColors.primaryRed,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _logoutBtn(),
        ],
      ),
    );
  }

  Widget _logoutBtn() {
    return Ink(
      decoration: const ShapeDecoration(
        shape: CircleBorder(),
        color: QColors.card,
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
        onPressed: _logout,
      ),
    );
  }

  /// -------- DATE SELECTOR --------
  Widget _dateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Text(
            _displayDate(selectedDate),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: QColors.text,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: QColors.primaryRed),
            onPressed: _pickDate,
          ),
        ],
      ),
    );
  }

  /// -------- BOTTOM NAVIGATION --------
  Widget _bottomNav() {
    const int activeIndex = 2; // <-- History = active

    final items = [
      {'icon': Icons.home_outlined, 'label': 'Main'},
      {'icon': Icons.verified_outlined, 'label': 'Approve'},
      {'icon': Icons.history, 'label': 'History'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: QColors.primaryRed,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final isActive = i == activeIndex;

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
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
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: isActive ? QColors.gold : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          color: isActive ? QColors.gold : Colors.white,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12.5,
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

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: QColors.gold),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: QColors.gold,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// -------- HISTORY CARD --------
class HistoryCard extends StatelessWidget {
  final dynamic item;

  const HistoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final s = int.tryParse(item['status'].toString()) ?? 0;

    final isApproved = s == 2;
    final isRejected = s == 3;

    final color = isApproved ? Colors.green : Colors.red;
    final icon = isApproved ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: const EdgeInsets.all(16),
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
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Name : ${item['name'] ?? 'Unknown'}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: QColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text("Room : ${item['room_number'] ?? '-'}"),
                Text("Time : ${item['time'] ?? '-'}"),
                Text("Date : ${item['room_date'] ?? '-'}"),
                const SizedBox(height: 4),
                Text(
                  isApproved ? "Approved" : "Rejected",
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                if (isRejected && item['reason'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Reason: ${item['reason']}",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
