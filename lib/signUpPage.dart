import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gptbets_sai_app/loginPage.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _obscureText = true;

  Future<void> _signUp() async {
    final String firstName = _firstNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (firstName.isEmpty) {
      _showErrorDialog("Please enter your name.");
      return;
    }

    if (!_isEmailValid(email)) {
      _showErrorDialog(
          "Please enter a valid email address.\n\nExample: name@domain.com");
      return;
    }

    if (!_isPasswordValid(password)) {
      _showErrorDialog(
          "Password must be at least 8 characters long and include uppercase, lowercase, numbers, and special characters.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      Navigator.pop(context); // Close loading dialog
      _showSuccessDialog(); // Show success message
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog("Error during sign-up: ${e.toString().split('] ')[1]}");
    }
  }

  bool _isEmailValid(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (email.isEmpty) return false;
    if (!emailRegex.hasMatch(email)) return false;
    if (email.length > 254) return false;
    if (email.startsWith('.') || email.endsWith('.')) return false;
    if (email.contains('..')) return false;

    final domain = email.split('@')[1];
    if (!domain.contains('.')) return false;
    if (domain.startsWith('-') || domain.endsWith('-')) return false;

    return true;
  }

  bool _isPasswordValid(String password) {
    final RegExp passwordRegex =
        RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$');
    return passwordRegex.hasMatch(password);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Color(0xFF59A52B), width: 1),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Color(0xFF59A52B),
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                "Error",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF59A52B),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF59A52B),
                    Color(0xFF468523),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "OK",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
          elevation: 8,
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 16),
          actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 16),
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Color(0xFF59A52B), width: 1),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Color(0xFF59A52B),
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                "Success",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF59A52B),
                ),
              ),
            ],
          ),
          content: Text(
            "Registration successful!\nYou'll be redirected to the login screen.",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF59A52B),
                    Color(0xFF468523),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: Text(
                  "OK",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
          elevation: 8,
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 16),
          actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 16),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image.asset('assets/lT.png',
                  height: MediaQuery.of(context).size.height * 0.32),
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Create Account',
                    textStyle: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF59A52B),
                    ),
                    speed: Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 1,
              ),
              SizedBox(height: 40),
              _buildTextField(
                  label: 'Name',
                  isPassword: false,
                  controller: _firstNameController),
              SizedBox(height: 20),
              _buildTextField(
                  label: 'Email',
                  isPassword: false,
                  controller: _emailController),
              SizedBox(height: 20),
              _buildPasswordTextField(),
              SizedBox(height: 30),
              _buildSignUpButton(),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Get.toNamed('/login'),
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    color: Color(0xFF59A52B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
      required bool isPassword,
      required TextEditingController controller}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF59A52B)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPasswordTextField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF59A52B)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _signUp,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF59A52B),
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        'Sign Up',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }
}
