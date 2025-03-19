import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:gptbets_sai_app/loginPage.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _loggediN = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _checkLoginStatus() {
    User? user = _auth.currentUser;
    setState(() {
      _loggediN = user != null;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = Color(0xFF59A52B);
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        leading: _loggediN
            ? IconButton(
                color: Color(0xFF59A52B),
                onPressed: () => _showLogoutConfirmation(context),
                icon: Icon(Icons.power_settings_new_outlined),
              )
            : IconButton(
                color: Color(0xFF59A52B),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ModalRoute.withName(''),
                  );
                },
                icon: Icon(Icons.arrow_back_ios),
              ),
        backgroundColor: Colors.black,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            'GPT Bets AI',
            style: GoogleFonts.orbitron(
              color: Color(0xFF59A52B),
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'AI-Powered Betting Insights',
                  textStyle: GoogleFonts.orbitron(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF59A52B),
                  ),
                  speed: Duration(milliseconds: 100),
                ),
              ],
              totalRepeatCount: 1,
            ),
            SizedBox(height: 12),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Get data-driven betting predictions with cutting-edge AI.',
                style: GoogleFonts.roboto(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 25),
            _loggediN
                ? ScaleTransition(
                    scale: _fadeAnimation,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.toNamed('/predictions');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF59A52B),
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        shadowColor: Colors.transparent,
                      ),
                      child: Text(
                        'View Predictions',
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : SizedBox(),
            SizedBox(height: _loggediN ? 30 : 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureTile(Icons.analytics, 'AI Analysis', onTap: () {
                    _loggediN
                        ? Get.toNamed('/predictions')
                        : Get.snackbar(
                            backgroundColor: Colors.white,
                            duration: Duration(seconds: 3),
                            colorText: Color(0xFF59A52B),
                            'Subscribe',
                            'Subscribe to access this feature');
                  }),
                  _buildFeatureTile(Icons.sports_soccer, 'Game Stats',
                      onTap: () {
                    _loggediN
                        ? Get.toNamed('/sportsHub')
                        : Get.snackbar(
                            backgroundColor: Colors.white,
                            duration: Duration(seconds: 3),
                            colorText: Color(0xFF59A52B),
                            'Subscribe',
                            'Subscribe to access this feature');
                  }),
                  _loggediN
                      ? _buildFeatureTile(Icons.article, 'Bets Analysis')
                      : SizedBox(),
                  _loggediN
                      ? _buildFeatureTile(Icons.chat_outlined, 'Chatroom',
                          onTap: () {
                          Get.toNamed('/chat');
                        })
                      : SizedBox(),
                ],
              ),
            ),
            if (!_loggediN)
              Center(
                child: Container(
                  margin: EdgeInsets.all(1),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [themeColor.withOpacity(0.8), themeColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_open,
                        size: 50,
                        color: Colors.white,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Unlock the Power of GPT BETS AI',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Subscribe now to access exclusive features and insights!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          Get.toNamed('/sub');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Subscribe Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF59A52B),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: launchUrlExample,
              icon: const Icon(
                Icons.sports_football,
                color: Colors.black,
              ),
              label: const Text(
                'Learn More',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, {Function()? onTap}) {
    return ScaleTransition(
      scale: _fadeAnimation,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Color(0xFF59A52B), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF59A52B).withOpacity(0.15),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Color(0xFF59A52B)),
              SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.orbitron(
              color: Color(0xFF59A52B),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'No',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _logout(context); // Proceed with logout
              },
              child: Text(
                'Yes',
                style: TextStyle(color: Color(0xFF59A52B)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Firebase logout function
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        ModalRoute.withName(''),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              'Error',
              style: GoogleFonts.orbitron(
                color: Color(0xFF59A52B),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              e.toString(),
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: Color(0xFF59A52B)),
                ),
              ),
            ],
          );
        },
      );
    }
  }
}

Future<void> launchUrlExample() async {
  final Uri url = Uri.parse('https://gptbets.io/');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.inAppBrowserView);
  } else {
    throw 'Could not launch $url';
  }
}
