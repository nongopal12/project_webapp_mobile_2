import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:project2/view/approver/proflie.dart'; 
import 'package:project2/view/login.dart';
import 'approve.dart';
import 'home.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime selectedDate = DateTime.now();
  List<dynamic> historyList = [];
  bool isLoading = true;

  // เปลี่ยนให้ตรงกับเซิร์ฟเวอร์ของคุณ
  final String baseUrl = "http://192.168.1.123:3000";

  int _toIntStatus(dynamic v) =>
      (v is int) ? v : (int.tryParse(v?.toString() ?? '') ?? 0);

  /// ✅ กรองทิ้งรายการที่เป็น Pending (status == 1 หรืออื่นๆ ที่ไม่ใช่ 2/3)
  List<dynamic> get visibleHistory =>
      historyList.where((h) {
        final s = _toIntStatus(h['status']);
        return s == 2 || s == 3; // 2=Approved, 3=Rejected
      }).toList();

  Future<void> fetchHistory() async {
    try {
      final dateStr =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      final url = Uri.parse('$baseUrl/api/history')
          .replace(queryParameters: {'date': dateStr});
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() {
          historyList = data;
          isLoading = false;
        });
      } else {
        throw Exception("Server error ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching history: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7A2E0C),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
      setState(() => isLoading = true);
      await fetchHistory();
    }
  }

  String formatDisplayDate(DateTime date) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log out successfully')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF7A2E0C);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: mainColor,
        title: const Text(
          'Approval History',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: mainColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  formatDisplayDate(selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              'History',
              style: TextStyle(
                color: Color(0xFF7A2E0C),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : visibleHistory.isEmpty
                    ? const Center(child: Text('No approved/rejected history.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: visibleHistory.length,
                        itemBuilder: (context, i) {
                          final h = visibleHistory[i];
                          final s = _toIntStatus(h['status']);

                          final status = (s == 2)
                              ? 'Approved'
                              : 'Rejected'; // เหลือแค่ 2/3 แล้ว

                          return OrderCard(
                            orderNumber:
                                "Name: ${h['name'] ?? h['username'] ?? 'Unknown'}",
                            room: "Room ${h['room_number'] ?? '-'}",
                            time: "Time: ${h['time'] ?? h['room_time'] ?? '-'}",
                            status: status,
                            rejectReason: h['reason']?.toString(),
                            date: h['room_date']?.toString() ?? '-',
                          );
                        },
                      ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: mainColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        currentIndex: 2,
        onTap: (i) {
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
                MaterialPageRoute(builder: (_) => const ProfileApproverPage()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Approve',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final String orderNumber;
  final String room;
  final String time;
  final String status;
  final String? rejectReason;
  final String date;

  const OrderCard({
    super.key,
    required this.orderNumber,
    required this.room,
    required this.time,
    required this.status,
    required this.date,
    this.rejectReason,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case 'Approved':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'Rejected':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.hourglass_bottom;
        color = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(room),
                Text(time),
                Text("Date: $date"),
                const SizedBox(height: 6),
                Text(status,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.bold)),
                if (status == 'Rejected' && rejectReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Reason: $rejectReason",
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(icon, color: color, size: 36),
        ],
      ),
    );
  }
}
