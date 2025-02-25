import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
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

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
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
            ScaleTransition(
              scale: _fadeAnimation,
              child: ElevatedButton(
                onPressed: () {
                  Get.toNamed('/predictions');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF59A52B),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
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
            ),
            SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureTile(Icons.analytics, 'AI Analysis'),
                  _buildFeatureTile(Icons.sports_soccer, 'Game Stats'),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF59A52B), // Button background color
                foregroundColor: Colors.black, // Text and icon color
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: launchUrlExample,
              icon: const Icon(
                Icons.sports_football,
                color: Colors.black,
              ), // Football-like icon
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

  Widget _buildFeatureTile(IconData icon, String title) {
    return ScaleTransition(
      scale: _fadeAnimation,
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
    );
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
