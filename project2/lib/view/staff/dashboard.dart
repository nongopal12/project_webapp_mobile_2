import 'package:flutter/material.dart';
// import 'history.dart'; // import ไฟล์ History
// import 'browse_room.dart'; // import ไฟล์ BrowseRoom (หน้า Edit)

/// Shell หลักสำหรับ Staff/Approver
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _index = 0;
  // กำหนดให้หน้าแรก (index 0) คือ DashboardBody ที่ดีไซน์ใหม่
  final _pages = const [DashboardBody()];

  void _onTap(int i, BuildContext context) {
    // ปุ่ม Logout จะอยู่ที่ index 3
    if (i == 3) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('Logged out')));
                // TODO: เพิ่มโค้ดเพื่อกลับไปยังหน้า Login
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // สีพื้นหลังโดยรวม
      body: _pages[_index],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Colors.grey.shade100, // สีพื้นหลังเข้ากับ body
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomNavigationBar(
            currentIndex: _index,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            backgroundColor: const Color(0xFF6A2E2E), // สีน้ำตาลแดงเข้ม
            type: BottomNavigationBarType.fixed,
            onTap: (i) => _onTap(i, context),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'HOME',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit_note_rounded),
                label: 'Edit',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.logout_rounded),
                label: 'Logout',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// -------------------- หน้า Dashboard (ดีไซน์ใหม่) --------------------
class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    // สร้าง list ของข้อมูลที่จะแสดงผล
    final items = [
      //  แก้ไขไอคอนตรงนี้
      _DashItem('Available', 10, Icons.groups_rounded, const [
        Color(0xFF1ECF73),
        Color(0xFF79E0A9),
      ]),
      _DashItem('Pending', 5, Icons.person_outline_rounded, const [
        Color(0xFFCFFADC),
        Color(0xFFE5F4EB),
      ]), // ปรับสี Pending ให้อ่อนลงตามรูป
      _DashItem('Reserved', 5, Icons.person_rounded, const [
        Color(0xFF5A9DFA),
        Color(0xFF88BBF7),
      ]),
      _DashItem('Disabled', 7, Icons.groups_rounded, const [
        Color(0xFFF26A6A),
        Color(0xFFF7A2A2),
      ]),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: items.length,
        // separatorBuilder ใช้สร้าง Widget คั่นระหว่างแต่ละรายการ
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        // itemBuilder ใช้สร้าง Card UI ของแต่ละรายการ
        itemBuilder: (context, index) {
          return _buildDashboardRow(items[index]);
        },
      ),
    );
  }

  /// Widget สำหรับสร้าง Card UI หนึ่งแถว
  Widget _buildDashboardRow(_DashItem item) {
    // เช็คว่าเป็น Pending หรือไม่ เพื่อเปลี่ยนสีข้อความ
    bool isPending = item.label == 'Pending';

    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            // วงกลมไอคอนด้านซ้าย
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: item.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              // ถ้าเป็น Pending ไอคอนจะเป็นสีเข้มขึ้นมาหน่อย
              child: Icon(
                item.icon,
                color: isPending ? Colors.green.shade700 : Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 20),
            // ข้อความด้านขวา
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.count} Rooms',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
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

// Class สำหรับเก็บข้อมูลของแต่ละรายการ
class _DashItem {
  final String label;
  final int count;
  final IconData icon;
  final List<Color> gradient;
  _DashItem(this.label, this.count, this.icon, this.gradient);
}
