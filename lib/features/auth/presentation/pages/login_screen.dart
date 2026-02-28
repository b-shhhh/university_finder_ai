import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../widgets/animated_cap.dart';

Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    final res = await ApiClient.I.post(
      ApiEndpoints.login,
      data: {"email": email, "password": password},
    );
    final data = res.data as Map<String, dynamic>;
    if ((res.statusCode ?? 400) == 200 && data['success'] == true) {
      final token = data['token']?.toString();
      if (token != null) await ApiClient.I.saveToken(token);
      return {"success": true, "token": token, "user": data['data']?['user']};
    }
    return {"success": false, "error": data['message'] ?? "Login failed"};
  } catch (e) {
    return {"success": false, "error": "Server error"};
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const Color primary = Color(0xFF0066B3);
  static const Color bg = Color(0xFFF7FBFF);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool showPassword = false;
  bool loading = false;
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginScreen.bg,
      body: SafeArea(child: _formPane(context)),
    );
  }

  Widget _formPane(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 520,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: LoginScreen.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("ACCOUNT ACCESS", style: TextStyle(color: Color(0xFF0066B3), fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Welcome back",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Sign in to continue your university search.",
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 20),
                    _input("Email address", _email, keyboard: TextInputType.emailAddress, validator: _emailValidator),
                    const SizedBox(height: 14),
                    _passwordInput("Password", _password),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                        child: const Text("Forgot password?"),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LoginScreen.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text("SIGN IN", style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                        child: const Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: Color(0xFF6B7280)),
                            children: [
                              TextSpan(text: "SIGN UP", style: TextStyle(color: Color(0xFF0C99C3), fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: -18,
              right: -10,
              child: AnimatedCap(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          validator: validator ?? (v) => (v == null || v.isEmpty) ? "Required" : null,
          decoration: _fieldDecoration(),
        ),
      ],
    );
  }

  Widget _passwordInput(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: !showPassword,
          validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
          decoration: _fieldDecoration().copyWith(
                suffixIcon: IconButton(
                  icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
              ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LoginScreen.primary, width: 1.6),
      ),
    );
  }

  String? _emailValidator(String? v) {
    if (v == null || v.isEmpty) return "Required";
    if (!v.contains('@') || !v.contains('.')) return "Enter a valid email";
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    final res = await login(_email.text.trim(), _password.text.trim());
    setState(() => loading = false);
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error'].toString())),
      );
    }
  }
}
