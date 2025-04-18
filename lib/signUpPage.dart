import 'package:cloud_firestore/cloud_firestore.dart'; // Add this for Firestore
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
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Add Firestore instance
  bool _obscureText = true;
  bool _isLoading = false; // Add loading state

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

    setState(() {
      _isLoading = true; // Set loading to true
    });

    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with display name
      await userCredential.user?.updateDisplayName(firstName);

      // Option 1: Save additional user details to Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'firstName': firstName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isLoading = false; // Set loading to false
      });

      _showSuccessDialog(); // Show success message
    } catch (e) {
      setState(() {
        _isLoading = false; // Set loading to false on error
      });
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
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF9CFF33), width: 1),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFF9CFF33),
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                "Error",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF9CFF33),
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
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF9CFF33),
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
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          actionsPadding: const EdgeInsets.fromLTRB(0, 0, 20, 16),
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF9CFF33), width: 1),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF9CFF33),
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                "Success",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF9CFF33),
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
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF9CFF33),
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
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          actionsPadding: const EdgeInsets.fromLTRB(0, 0, 20, 16),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
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
                      color: Color(0xFF9CFF33),
                    ),
                  )
                ],
                totalRepeatCount: 1,
              ),
              const SizedBox(height: 40),
              _buildTextField(
                  label: 'Name',
                  isPassword: false,
                  controller: _firstNameController),
              const SizedBox(height: 20),
              _buildTextField(
                  label: 'Email',
                  isPassword: false,
                  controller: _emailController),
              const SizedBox(height: 20),
              _buildPasswordTextField(),
              const SizedBox(height: 30),
              _buildSignUpButton(),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Get.toNamed('/login'),
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    color: Color(0xFF9CFF33),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF9CFF33)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPasswordTextField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF9CFF33)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
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
      onPressed: _isLoading ? null : _signUp, // Disable button when loading
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9CFF33),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.black)
          : Text(
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
