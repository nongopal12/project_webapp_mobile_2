import 'package:flutter/material.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

bool _obscurePwd = true;

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _idCtl = TextEditingController();
  final _pwdCtl = TextEditingController();
  bool _loading = false;
  final _api = AuthApi(); // ปรับ baseUrl หากจำเป็น

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
      await _api.login(
        emailOrPhone: _idCtl.text.trim(),
        password: _pwdCtl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login success!')));
        // TODO: ไปหน้า Home
      }
    } on Exception catch (e) {
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      fontFamily: 'Roboto', // หรือฟอนต์อื่นก็ได้
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(blurRadius: 10, color: Colors.black12),
                    ],
                  ),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 22,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.red,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _idCtl,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter email'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pwdCtl,
                          obscureText: _obscurePwd,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePwd
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePwd = !_obscurePwd;
                                });
                              },
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty || v.length < 6)
                              ? 'Password must be at least 6 chars'
                              : null,
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Confirm Login'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.gold,
                              width: 2,
                            ),
                            foregroundColor: AppColors.gold,
                          ),
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppColors {
  static const red = Color(0xFF7B3028);
  static const gold = Color(0xFFFFC107);
}

class AuthApi {
  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    if (emailOrPhone != 'admin' || password != '123456') {
      throw Exception('Invalid credentials');
    }
  }
}