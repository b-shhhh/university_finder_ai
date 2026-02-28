import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../app/theme/app_colors.dart';
import '../widgets/animated_cap.dart';

Future<bool> register({
  required String fullName,
  required String email,
  required String password,
  required String phone,
  String countryCode = '+1',
}) async {
  try {
    final res = await ApiClient.I.post(
      ApiEndpoints.register,
      data: {
        "fullName": fullName,
        "email": email,
        "password": password,
        "confirmPassword": password,
        "phone": phone,
        "countryCode": countryCode,
      },
    );
    final token = (res.data as Map<String, dynamic>)['token']?.toString();
    if (token != null) await ApiClient.I.saveToken(token);
    return (res.statusCode ?? 400) >= 200 && (res.statusCode ?? 0) < 300;
  } catch (e) {
    debugPrint("Register error: $e");
    return false;
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  final Color primary = AppColors.primary;
  final Color bg = const Color(0xFFF7FBFF);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool loading = false;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final countryCodeController = TextEditingController(text: "+1");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.bg,
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
                      child: const Text("NEW ACCOUNT", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Create account",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Sign up to build your university shortlist.",
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 20),
                    _input("Full name", fullNameController),
                    const SizedBox(height: 14),
                    _input("Email", emailController, keyboard: TextInputType.emailAddress, validator: _emailValidator),
                    const SizedBox(height: 14),
                    _passwordInput("Password", passwordController, isConfirm: false),
                    const SizedBox(height: 14),
                    _passwordInput("Confirm password", confirmPasswordController, isConfirm: true),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _input("Country code", countryCodeController, keyboard: TextInputType.phone),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _input("Phone number", phoneController, keyboard: TextInputType.phone),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
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
                            : const Text("REGISTER", style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text.rich(
                    TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Color(0xFF6B7280)),
                      children: [
                          TextSpan(text: "LOGIN", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -18,
              right: -10,
              child: AnimatedCap(
                color: widget.primary,
                shadowColor: widget.primary.withOpacity(0.25),
              ),
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

  Widget _passwordInput(String label, TextEditingController ctrl, {required bool isConfirm}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: isConfirm ? !showConfirmPassword : !showPassword,
          validator: (v) {
            if (v == null || v.isEmpty) return "Required";
            if (isConfirm && v != passwordController.text) return "Passwords do not match";
            if (!isConfirm && v.length < 6) return "Min 6 characters";
            return null;
          },
          decoration: _fieldDecoration().copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    (isConfirm ? showConfirmPassword : showPassword) ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF94A3B8),
                  ),
                  onPressed: () => setState(
                    () => isConfirm ? showConfirmPassword = !showConfirmPassword : showPassword = !showPassword,
                  ),
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

    final ok = await register(
      fullName: fullNameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      phone: phoneController.text.trim(),
      countryCode: countryCodeController.text.trim(),
    );

    setState(() => loading = false);
    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup failed. Please try again.")),
      );
    }
  }
}

