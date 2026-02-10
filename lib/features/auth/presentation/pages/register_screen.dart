import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// API call
Future<bool> register({
  required String firstName,
  required String lastName,
  required String email,
  required String password,
  required String phone,
  required String education,
}) async {
  final url = Uri.parse("http://10.0.2.2:3000/api/auth/register");

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "firstname": firstName,
        "lastname": lastName,
        "email": email,
        "password": password,
        "phone": phone,
        "education": education,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    print("Flutter error: $e");
    return false;
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedEducation;
  bool showPassword = false;
  bool showConfirmPassword = false;

  // Controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Colors
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
              'Your academic journey starts here',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

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
            _buildTextField('First Name', Icons.person_outline, controller: firstNameController),
            const SizedBox(height: 16),
            _buildTextField('Last Name', Icons.person_outline, controller: lastNameController),
            const SizedBox(height: 16),
            _buildTextField('Email Address', Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress, controller: emailController),
            const SizedBox(height: 24),
            _buildPasswordField('Password', showPassword, () => setState(() => showPassword = !showPassword),
                controller: passwordController),
            const SizedBox(height: 16),
            _buildPasswordField(
                'Confirm Password', showConfirmPassword, () => setState(() => showConfirmPassword = !showConfirmPassword),
                controller: confirmPasswordController),
            const SizedBox(height: 16),
            _buildTextField('Phone', Icons.phone_iphone_rounded, keyboardType: TextInputType.phone, controller: phoneController),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedEducation,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              decoration: _inputDecoration('Education', Icons.school_outlined),
              style: const TextStyle(color: Colors.black, fontSize: 15),
              items: ['High School', 'Bachelors', 'Masters']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14, color: Colors.black)))).toList(),
              onChanged: (v) => setState(() => selectedEducation = v),
              validator: (v) => v == null || v.isEmpty ? 'Please select your education' : null,
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: const TextStyle(color: Colors.black54),
                    children: [
                      TextSpan(
                        text: 'Login',
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

  Widget _buildTextField(String hint, IconData icon,
      {TextInputType keyboardType = TextInputType.text, TextEditingController? controller}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Colors.black),
      decoration: _inputDecoration(hint, icon),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter $hint';
        if (hint == 'Email Address' && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        if (hint == 'Phone' && value.length < 7) return 'Please enter a valid phone';
        return null;
      },
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
      validator: (value) => value == null || value.isEmpty ? 'Please enter $hint' : null,
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

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryBrand.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            // ✅ Confirm password match
            if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Passwords do not match")),
              );
              return;
            }

            bool success = await register(
              firstName: firstNameController.text.trim(),
              lastName: lastNameController.text.trim(),
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
              phone: phoneController.text.trim(),
              education: selectedEducation!,
            );

            if (success) {
              Navigator.pushReplacementNamed(context, '/dashboard');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Signup failed. Check console for details.")),
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
        child: const Text(
          'Register',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
