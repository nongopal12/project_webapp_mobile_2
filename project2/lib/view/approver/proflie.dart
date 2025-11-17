import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project2/view/approver/home.dart';
import 'package:project2/view/approver/approve.dart';
import 'package:project2/view/approver/history_approver.dart';
import 'package:project2/view/login.dart';

const String kBaseUrl = "http://192.168.1.123:3000"; // แก้ให้ตรง backend

class PColors {
  static const bg = Color(0xFFF7F7F9);
  static const primaryRed = Color(0xFF7A2E22);
  static const gold = Color(0xFFCC9A2B);
  static const card = Colors.white;
  static const text = Color(0xFF2E2E2E);
}

class ProfileApproverPage extends StatefulWidget {
  const ProfileApproverPage({super.key});
  @override
  State<ProfileApproverPage> createState() => _ProfileApproverPageState();
}

class _ProfileApproverPageState extends State<ProfileApproverPage> {
  int _currentIndex = 3;
  bool _loading = true;
  String? _error;

  int? _userId;
  String _username = '';
  String _email = '';
  String _role = 'Approver';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final username = sp.getString('username') ?? 'admin';
      final uri = Uri.parse('$kBaseUrl/api/profile/$username');
      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('โหลดโปรไฟล์ไม่สำเร็จ');
      final data = json.decode(res.body);
      _userId = int.tryParse('${data['id'] ?? data['user_id'] ?? ''}');
      _username = (data['username'] ?? '').toString();
      _email = (data['user_email'] ?? '').toString();
      _role = (data['role_name'] ?? 'Approver').toString();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PColors.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text('ผิดพลาด: $_error'))
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: EmployeeIdCardHorizontal(
                    name: _username.isEmpty ? '-' : _username,
                    role: _role,
                    employeeId: _userId == null ? '-' : '#${_userId!}',
                    email: _email,
                    department: 'QuickRoom System',
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    const items = [
      _NavSpec('Main', Icons.home_outlined),
      _NavSpec('Approver', Icons.verified_outlined),
      _NavSpec('History', Icons.history),
      _NavSpec('Profile', Icons.person_outline),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: PColors.primaryRed,
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
                      break;
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i].icon,
                      size: 22,
                      color: active ? PColors.gold : Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        color: active ? PColors.gold : Colors.white,
                        fontSize: 12.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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

class _NavSpec {
  final String label;
  final IconData icon;
  const _NavSpec(this.label, this.icon);
}

/// ===== บัตรพนักงานแนวนอน (ไม่มีรูป) =====
class EmployeeIdCardHorizontal extends StatelessWidget {
  final String name;
  final String role;
  final String employeeId;
  final String department;
  final String email;
  const EmployeeIdCardHorizontal({
    super.key,
    required this.name,
    required this.role,
    required this.employeeId,
    required this.department,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 360;
    const double cardHeight = 230;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [PColors.primaryRed, Color(0xFF5A1F18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // แถบทองด้านบน
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 42,
            child: Container(
              color: PColors.gold,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'EMPLOYEE CARD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          // เนื้อใน
          Positioned.fill(
            top: 42,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ช่องซ้าย (แทนรูป)
                  Container(
                    width: 100,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(.6),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: PColors.primaryRed,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // ช่องขวา (ข้อมูล)
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            role,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _kv('ID', employeeId),
                          _kv('Department', department),
                          _kv('Email', email),
                          const SizedBox(height: 10),
                          Container(
                            width: 140,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // มุมล่างขวา
          Positioned(
            right: 14,
            bottom: 8,
            child: Text(
              employeeId,
              style: TextStyle(
                color: Colors.white.withOpacity(.95),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$k :',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(fontSize: 12.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
