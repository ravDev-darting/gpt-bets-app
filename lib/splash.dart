import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gptbets_sai_app/homeSc.dart';
import 'package:gptbets_sai_app/loginPage.dart';

class SplashScreenMain extends StatefulWidget {
  const SplashScreenMain({super.key});

  @override
  State<SplashScreenMain> createState() => _SplashScreenMainState();
}

class _SplashScreenMainState extends State<SplashScreenMain> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    Timer(const Duration(seconds: 2), () {
      _checkLoginStatus();
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/lT.png',
                height: MediaQuery.of(context).size.height * 0.4),
            const CircularProgressIndicator(
              color: Color(0xFF59A52B),
            )
          ],
        ),
      ),
    );
  }

  // Check if the user is already logged in
  void _checkLoginStatus() {
    User? user = _auth.currentUser;

    // Navigate based on the login status
    if (user != null) {
      // If the user is logged in, navigate to DashScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        ModalRoute.withName(''),
      );
    } else {
      // If the user is not logged in, navigate to LoginScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        ModalRoute.withName(''),
      );
    }
  }
}
