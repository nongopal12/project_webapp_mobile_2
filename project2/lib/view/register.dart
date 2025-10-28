import 'package:flutter/material.dart';

/// ====== สีที่ใช้ทั้งหน้า ======
class AppColors {
  static const red = Color(0xFF7B3028);
  static const gold = Color.fromRGBO(255, 193, 7, 1);
}

/// ====== Mock API สำหรับสมัครสมาชิก ======
/// ถ้ามีแบ็กเอนด์จริง ค่อยเปลี่ยนเนื้อในฟังก์ชัน register ให้ยิง HTTP
class AuthApi {
  Future<void> register({
    required String emailOrPhone,
    required String name,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (emailOrPhone.isEmpty || name.isEmpty || password.length < 6) {
      throw Exception('Invalid register data');
    }
    // ตัวอย่าง: สมมติว่าบัญชีนี้ถูกใช้ไปแล้ว
    if (emailOrPhone == 'admin') {
      throw Exception('This email/phone is already in use');
    }
    // สำเร็จ -> เงียบ ๆ (void)
  }
}

/// ====== Register Page ======
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _idCtl = TextEditingController();
  final _nameCtl = TextEditingController();
  final _pwdCtl = TextEditingController();
  final _pwd2Ctl = TextEditingController();

  bool _loading = false;
  bool _obscurePwd = true;
  bool _obscurePwd2 = true;

  final _api = AuthApi();

  @override
  void dispose() {
    _idCtl.dispose();
    _nameCtl.dispose();
    _pwdCtl.dispose();
    _pwd2Ctl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _api.register(
        emailOrPhone: _idCtl.text.trim(),
        name: _nameCtl.text.trim(),
        password: _pwdCtl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Register success! Please login.')),
        );
        Navigator.pop(context); // ย้อนกลับไปหน้า Login
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Register failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create account',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email / Phone
                  TextFormField(
                    controller: _idCtl,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Please enter email/phone' : null,
                  ),
                  const SizedBox(height: 12),

                  // Name
                  TextFormField(
                    controller: _nameCtl,
                    decoration: const InputDecoration(
                      hintText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                  ),
                  const SizedBox(height: 12),

                  // Password + toggle
                  TextFormField(
                    controller: _pwdCtl,
                    obscureText: _obscurePwd,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePwd ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black,
                        ),
                        onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                        tooltip: _obscurePwd ? 'Show password' : 'Hide password',
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 12),

                  // Again-Password + toggle
                  TextFormField(
                    controller: _pwd2Ctl,
                    obscureText: _obscurePwd2,
                    decoration: InputDecoration(
                      hintText: 'Confirm-Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePwd2 ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black,
                        ),
                        onPressed: () => setState(() => _obscurePwd2 = !_obscurePwd2),
                        tooltip: _obscurePwd2 ? 'Show password' : 'Hide password',
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please re-enter password';
                      if (v != _pwdCtl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirm Register'),
                  ),
                  const SizedBox(height: 8),

                  OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gold, width: 2),
                      foregroundColor: AppColors.gold,
                    ),
                    child: const Text('Back To Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
