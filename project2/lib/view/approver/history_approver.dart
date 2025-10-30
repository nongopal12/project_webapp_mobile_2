import 'package:flutter/material.dart';
import 'package:project2/view/login.dart';
import 'proflie.dart';
import 'approve.dart';
import 'home.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime selectedDate = DateTime.now();

  // ✅ ฟังก์ชันเปิด DatePicker (เลือกวัน/เดือน/ปี)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

// ✅ ฟังก์ชันยืนยันการออกจากระบบ
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
    // ✅ แสดงข้อความ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log out successfully')),
    );

    // ✅ กลับไปหน้า Login (แทนที่ stack ทั้งหมด)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

  // ฟังก์ชันแปลงวันที่เป็นข้อความ (ไม่ใช้ intl)
  String getFormattedDate(DateTime date) {
    final List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = getFormattedDate(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A2E0C),
        title: const Text(
          'QuickRoom',
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
          // Calendar Header (เลือกวันได้)
          Container(
            color: const Color(0xFF7A2E0C),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.calendar_today,
                      color: Colors.white, size: 18),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Text(
              'Approval History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7A2E0C),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ✅ แสดงเฉพาะ Approved / Rejected
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                OrderCard(
                  orderNumber: 'ORDER0001',
                  room: 'Room 10',
                  time: '12.00',
                  status: 'Approved',
                ),
                OrderCard(
                  orderNumber: 'ORDER0002',
                  room: 'Room 11',
                  time: '12.00',
                  status: 'Rejected',
                  rejectReason: 'Room not available at this time.',
                ),
                OrderCard(
                  orderNumber: 'ORDER0003',
                  room: 'Room 12',
                  time: '12.00',
                  status: 'Rejected',
                  rejectReason: 'Room not available at this time.',
                ),
              ],
            ),
          ),
        ],
      ),

      // ✅ Bottom Navigation (เชื่อมเหมือนหน้าอื่น)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF7A2E0C),
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
              // หน้าปัจจุบัน
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
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Approver'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ======= Card แสดงประวัติ =======
class OrderCard extends StatelessWidget {
  final String orderNumber;
  final String room;
  final String time;
  final String status;
  final String? rejectReason;

  const OrderCard({
    super.key,
    required this.orderNumber,
    required this.room,
    required this.time,
    required this.status,
    this.rejectReason,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData icon;

    switch (status) {
      case 'Approved':
        statusColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        icon = Icons.hourglass_bottom;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Number : $orderNumber',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Room : $room'),
                Text('Time : $time'),
                const SizedBox(height: 6),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (status == 'Rejected' && rejectReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reason : $rejectReason',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(icon, color: statusColor, size: 35),
        ],
      ),
    );
  }
}
