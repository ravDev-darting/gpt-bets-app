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

  Future<void> signUpWithEmailAndPassword(BuildContext context) async {
    try {
      // Check if all fields are filled
      if (_firstNameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty) {
        // Create user with email and password
        // ignore: unused_local_variable
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Ge

        // Navigate to the next screen after successful sign-up
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        Get.snackbar('Error', 'Please fill in all fields!',
            colorText: Colors.white,
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      // Handle errors
      print('Error during sign-up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during sign-up: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
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
            _buildTextField(
                label: 'Password',
                isPassword: true,
                controller: _passwordController),
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
          ],
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

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: () => signUpWithEmailAndPassword(context),
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
