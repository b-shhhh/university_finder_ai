import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ================= LOGIN API =================
Future<Map<String, dynamic>> login(String email, String password) async {
  final url = Uri.parse("http://10.0.2.2:3000/api/auth/login"); // Android emulator fix

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return {"success": true, "token": data['token'], "user": data['user']};
    } else {
      return {"success": false, "error": data['error'] ?? "Login failed"};
    }
  } catch (e) {
    return {"success": false, "error": "Server error"};
  }
}

// ================= LOGIN SCREEN =================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool showPassword = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final Color primaryBrand = const Color(0xFF4E4AF2);
  final Color secondaryBrand = const Color(0xFF7B78FF);
  final Color background = const Color(0xFFF8F9FE);
  final Color surface = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: _buildFormCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBrand, secondaryBrand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(scale: value, child: child),
                );
              },
              child: const Icon(Icons.school_rounded, size: 70, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'UniGuide',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const Text(
              'Login back to your account',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  // ================= FORM CARD =================
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              'Email Address',
              Icons.alternate_email_rounded,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              'Password',
              showPassword,
                  () => setState(() => showPassword = !showPassword),
              controller: _passwordController,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSubmitButton(),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: const TextStyle(color: Colors.black54),
                    children: [
                      TextSpan(
                        text: 'Register',
                        style: TextStyle(color: primaryBrand, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INPUTS =================
  Widget _buildTextField(
      String hint, IconData icon,
      {TextInputType keyboardType = TextInputType.text, TextEditingController? controller}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Colors.black),
      decoration: _inputDecoration(hint, icon),
      validator: (value) => value == null || value.isEmpty ? 'Please enter ${hint.toLowerCase()}' : null,
    );
  }

  Widget _buildPasswordField(String hint, bool visible, VoidCallback toggle, {TextEditingController? controller}) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      style: const TextStyle(fontSize: 15, color: Colors.black),
      decoration: _inputDecoration(hint, Icons.lock_outline_rounded).copyWith(
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.black),
          onPressed: toggle,
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Please enter ${hint.toLowerCase()}' : null,
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54, fontSize: 15),
      prefixIcon: Icon(icon, size: 20, color: Colors.black54),
      filled: true,
      fillColor: background,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryBrand.withOpacity(0.5), width: 1.5),
      ),
    );
  }

  // ================= SUBMIT BUTTON =================
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: primaryBrand.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            final result = await login(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );

            if (result['success']) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Login successful!")),
              );
              Navigator.pushReplacementNamed(context, '/dashboard');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['error'])),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrand,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
