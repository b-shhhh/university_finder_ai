import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

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
  LoginScreen({super.key});
  final Color primary = const Color(0xFF0066B3);
  final Color bg = const Color(0xFFF7FBFF);

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
      backgroundColor: widget.bg,
      body: SafeArea(
        child: Row(
          children: [
            _heroPane(),
            Expanded(child: _formPane(context)),
          ],
        ),
      ),
    );
  }

  Widget _heroPane() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF0C99C3), Color(0xFF045C88)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _logo(),
            const SizedBox(height: 32),
            const Text(
              "Find the right\nuniversity with less\nguesswork.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Compare universities, tuition, and courses in one focused dashboard built for students making real decisions.",
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            _statsRow(),
          ],
        ),
      ),
    );
  }

  Widget _logo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.school, color: Colors.white),
          SizedBox(width: 10),
          Text(
            "UNIGUIDE\nAI University Finder",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    Widget stat(String value, String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );
    }

    return Row(
      children: [
        stat("1000+", "UNIVERSITIES"),
        const SizedBox(width: 10),
        stat("60+", "COUNTRIES"),
        const SizedBox(width: 10),
        stat("24/7", "ACCESS"),
      ],
    );
  }

  Widget _formPane(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 540,
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
                    color: widget.primary.withOpacity(0.08),
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
                      backgroundColor: widget.primary,
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
        borderSide: BorderSide(color: widget.primary, width: 1.6),
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
