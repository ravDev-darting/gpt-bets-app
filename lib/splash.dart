import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gptbets_sai_app/homeSc.dart';
import 'package:gptbets_sai_app/loginPage.dart';

class SplashScreenMain extends StatefulWidget {
  const SplashScreenMain({super.key});

  @override
  State<SplashScreenMain> createState() => _SplashScreenMainState();
}

class _SplashScreenMainState extends State<SplashScreenMain>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Configure animations
    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations
    _controller.forward();

    // Check login status after animations complete
    Timer(const Duration(seconds: 2), _checkLoginStatus);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with fade and scale animation
            FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/lT.png',
                  height: MediaQuery.of(context).size.height * 0.4,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Progress indicator with slide animation
            SlideTransition(
              position: _slideAnimation,
              child: const CircularProgressIndicator(
                color: Color(0xFF9CFF33),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkLoginStatus() async {
    User? user = _auth.currentUser;

    if (user != null) {
      // Get user doc from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();
      final hasLoggedInBefore = data != null && data['lastLogin'] != null;

      if (hasLoggedInBefore) {
        // Navigate to Home
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
          (route) => false,
        );
      } else {
        // Navigate to LoginScreen
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
          (route) => false,
        );
      }
    } else {
      // No user signed in
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // void _checkLoginStatus() {
  //   User? user = _auth.currentUser;

  //   if (user != null) {
  //     Navigator.pushAndRemoveUntil(
  //       context,
  //       PageRouteBuilder(
  //         pageBuilder: (context, animation, secondaryAnimation) =>
  //             const HomeScreen(),
  //         transitionsBuilder: (context, animation, secondaryAnimation, child) {
  //           return FadeTransition(
  //             opacity: animation,
  //             child: child,
  //           );
  //         },
  //         transitionDuration: const Duration(milliseconds: 800),
  //       ),
  //       (route) => false,
  //     );
  //   } else {
  //     Navigator.pushAndRemoveUntil(
  //       context,
  //       PageRouteBuilder(
  //         pageBuilder: (context, animation, secondaryAnimation) =>
  //             const LoginScreen(),
  //         transitionsBuilder: (context, animation, secondaryAnimation, child) {
  //           return SlideTransition(
  //             position: Tween<Offset>(
  //               begin: const Offset(0, 1),
  //               end: Offset.zero,
  //             ).animate(animation),
  //             child: child,
  //           );
  //         },
  //         transitionDuration: const Duration(milliseconds: 800),
  //       ),
  //       (route) => false,
  //     );
  //   }
  // }
}
