import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register.dart';


import 'package:shared_preferences/shared_preferences.dart';


import 'package:project2/view/staff/dashboard.dart';
import 'package:project2/view/user/booking_room.dart';
import 'package:project2/view/approver/home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _idCtl = TextEditingController();
  final _pwdCtl = TextEditingController();
  bool _loading = false;
  bool _obscurePwd = true;

  final _api = AuthApi();

  @override
  void dispose() {
    _idCtl.dispose();
    _pwdCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final role = await _api.login(
        username: _idCtl.text.trim(),
        password: _pwdCtl.text,
      );

      if (!mounted) return;

      Widget nextPage;
      switch (role) {
        case 'staff':
          nextPage = Dashboard(username: _idCtl.text.trim());
          break;
        case 'approver':
          nextPage = const HomeApprover();
          break;
        case 'user':
          nextPage = const UserHomePage();
          break;
        default:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid role')));
          return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login success as $role')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shadowColor: AppColors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ===== โลโก้พร้อมไอคอน =====
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.red, AppColors.red],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.red,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.meeting_room_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ===== โลโก้ QuickRoom =====
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 32,
                            fontFamily: 'Roboto',
                            letterSpacing: 1.2,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Quick',
                              style: TextStyle(color: AppColors.red),
                            ),
                            TextSpan(
                              text: 'Room',
                              style: TextStyle(color: AppColors.gold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome back!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ===== ฟอร์ม Login =====
                      Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Username Field
                            TextFormField(
                              controller: _idCtl,
                              decoration: InputDecoration(
                                hintText: 'Username',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: AppColors.red,
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Please enter username'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _pwdCtl,
                              obscureText: _obscurePwd,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppColors.red,
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.red,
                                    width: 2,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePwd
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePwd = !_obscurePwd);
                                  },
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Enter password'
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // Login Button
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.red, Color(0xFF9B4036)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.red,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: Colors.grey[300]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: Colors.grey[300]),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Register Button
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.gold,
                                  width: 2,
                                ),
                              ),
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterPage(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide.none,
                                  foregroundColor: AppColors.gold,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Create New Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ====== สีหลักของระบบ ======
class AppColors {
  static const red = Color(0xFF7B3028);
  static const gold = Color(0xFFFFC107);
}

// ====== API เชื่อมกับ Node.js + เก็บ session ======
class AuthApi {
  // ✅ ให้ใช้ IP เดียวกับ HistoryPage
  final String baseUrl = "http://172.27.13.156:3000";

  // ✅ ตัวแปร static ให้หน้าอื่นอ้างอิงได้
  static int? userId;
  static String? username;
  static String? role;
  static String? token;

  /// ✅ ใช้เวลาจะยิง API ที่ต้องส่ง token
  Map<String, String> get authHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<String> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/api/login");

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      // 📝 สมมติ backend ส่งกลับมาแบบนี้:
      // { message, id, role, username, email, token? }

      // ✅ เก็บค่าไว้ใน static
      userId = data['id'];
      role = data['role'];
      AuthApi.username = data['username'] ?? username;
      token = data['token']; // ถ้า backend ยังไม่มี token ตรงนี้จะเป็น null เฉย ๆ ไม่พัง

      // ✅ เก็บลง SharedPreferences ให้หน้าอื่นดึงใช้ได้
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) await prefs.setInt('uid', userId!);
      if (role != null) await prefs.setString('role', role!);
      if (AuthApi.username != null) {
        await prefs.setString('username', AuthApi.username!);
      }
      if (token != null) {
        await prefs.setString('token', token!);
      }

      return data['role'];
    } else {
      throw Exception("Invalid credentials or server error");
    }
  }
}
