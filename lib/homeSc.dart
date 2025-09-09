import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:gptbets_sai_app/loginPage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
  bool _isSubscribed = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _checkLoginAndSubscriptionStatus();

    // Listen to purchase updates
    _purchaseSubscription = InAppPurchase.instance.purchaseStream
        .listen(_listenToPurchases, onError: (error) {
      print('Purchase stream error: $error');
    });

    // Trigger restore purchases for iOS promo codes
    if (Platform.isIOS) {
      InAppPurchase.instance.restorePurchases();
    }
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLoginAndSubscriptionStatus() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() => _loggediN = true);

      try {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final subscription = data['subscription'];

          if (subscription != null && subscription['isActive'] == true) {
            DateTime now = DateTime.now();
            DateTime? expiryDate;

            if (subscription['expiryDate'] != null) {
              if (subscription['expiryDate'] is Timestamp) {
                expiryDate = (subscription['expiryDate'] as Timestamp).toDate();
              } else if (subscription['expiryDate'] is String) {
                expiryDate = DateTime.tryParse(subscription['expiryDate']);
              }
            }

            if (expiryDate != null && now.isBefore(expiryDate)) {
              setState(() => _isSubscribed = true);
            } else {
              // Expired
              await _firestore.collection('users').doc(user.uid).set({
                'subscription': {'isActive': false}
              }, SetOptions(merge: true));
              setState(() => _isSubscribed = false);
            }
          } else {
            setState(() => _isSubscribed = false);
          }
        } else {
          setState(() => _isSubscribed = false);
        }
      } catch (e) {
        print('Error fetching subscription status: $e');
        setState(() => _isSubscribed = false);
      }
    } else {
      setState(() {
        _loggediN = false;
        _isSubscribed = false;
      });
    }
  }

  void _listenToPurchases(List<PurchaseDetails> purchases) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (var purchaseDetails in purchases) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        DateTime? expiryDate;
        final purchaseDate = DateTime.now();

        switch (purchaseDetails.productID) {
          case 'com.gptbetsai.weekly_v1':
            expiryDate = purchaseDate.add(const Duration(days: 7));
            break;
          case 'com.gptbetsai.monthly_v1':
            expiryDate = DateTime(
                purchaseDate.year, purchaseDate.month + 1, purchaseDate.day);
            break;
          case 'com.gptbetsai.yearly_v1':
            expiryDate = DateTime(
                purchaseDate.year + 1, purchaseDate.month, purchaseDate.day);
            break;
        }

        if (expiryDate != null && expiryDate.isAfter(DateTime.now())) {
          // ✅ Save to Firestore only if valid
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'subscription': {
              'productId': purchaseDetails.productID,
              'status': 'active',
              'expiryDate': expiryDate,
              'isActive': true,
            },
          }, SetOptions(merge: true));

          // Update local state
          setState(() => _isSubscribed = true);
        }

        // Complete the purchase
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = const Color(0xFF9CFF33);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final bool isMediumScreen = screenWidth >= 600 && screenWidth < 900;
    final bool isLargeScreen = screenWidth >= 900;

    final double titleFontSize = isSmallScreen
        ? 20
        : isMediumScreen
            ? 24
            : 28;
    final double subtitleFontSize = isSmallScreen
        ? 14
        : isMediumScreen
            ? 16
            : 18;
    final double buttonFontSize = isSmallScreen
        ? 14
        : isMediumScreen
            ? 16
            : 18;

    final double horizontalPadding = isSmallScreen
        ? 16
        : isMediumScreen
            ? 24
            : 32;
    final double verticalPadding = isSmallScreen
        ? 16
        : isMediumScreen
            ? 24
            : 32;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        leading: _loggediN
            ? IconButton(
                color: themeColor,
                onPressed: () => _showLogoutConfirmation(context),
                icon: const Icon(Icons.power_settings_new_outlined),
              )
            : IconButton(
                color: themeColor,
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ModalRoute.withName(''),
                  );
                },
                icon: const Icon(Icons.arrow_back_ios),
              ),
        backgroundColor: Colors.black,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            'GPTBETS AI',
            style: GoogleFonts.orbitron(
              color: themeColor,
              fontWeight: FontWeight.w600,
              fontSize: titleFontSize,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: verticalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: isSmallScreen ? 8 : 16),
                  AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        cursor: '',
                        'AI-Powered Betting',
                        textStyle: GoogleFonts.orbitron(
                          fontSize: isSmallScreen
                              ? 22
                              : isMediumScreen
                                  ? 28
                                  : 32,
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                        ),
                        speed: const Duration(milliseconds: 100),
                      ),
                    ],
                    totalRepeatCount: 1,
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 16),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'AI Sports Betting Assistant\nYour sports betting coach — in your pocket.',
                      style: GoogleFonts.roboto(
                        color: Colors.grey,
                        fontSize: subtitleFontSize,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final int crossAxisCount = constraints.maxWidth > 900
                            ? 4
                            : constraints.maxWidth > 600
                                ? 3
                                : 2;
                        final double childAspectRatio = isSmallScreen
                            ? 0.85
                            : isMediumScreen
                                ? 1.0
                                : 1.1;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: isSmallScreen ? 12 : 16,
                          mainAxisSpacing: isSmallScreen ? 12 : 16,
                          childAspectRatio: childAspectRatio,
                          children: [
                            _buildFeatureTile(
                              Icons.analytics,
                              'GPTBETS AI Assistant',
                              isSmallScreen: isSmallScreen,
                              onTap: () {
                                if (_loggediN && _isSubscribed) {
                                  Get.toNamed('/chatBot');
                                } else {
                                  Get.snackbar(
                                    backgroundColor: Colors.white,
                                    duration: const Duration(seconds: 3),
                                    colorText: Colors.black,
                                    'Subscribe',
                                    'Subscribe to access this feature',
                                  );
                                }
                              },
                            ),
                            _buildFeatureTile(
                              Icons.sports_soccer,
                              'Sports Hub',
                              isSmallScreen: isSmallScreen,
                              onTap: () {
                                if (_loggediN) {
                                  Get.toNamed('/sportsHub');
                                } else {
                                  Get.snackbar(
                                    backgroundColor: Colors.white,
                                    duration: const Duration(seconds: 3),
                                    colorText: Colors.black,
                                    'Register',
                                    'Register yourself up to access this feature!!',
                                  );
                                }
                              },
                            ),
                            if (_loggediN)
                              _buildFeatureTile(
                                Icons.chat_outlined,
                                'Chatroom',
                                isSmallScreen: isSmallScreen,
                                onTap: () {
                                  if (_isSubscribed) {
                                    Get.toNamed('/chat');
                                  } else {
                                    Get.snackbar(
                                      backgroundColor: Colors.white,
                                      duration: const Duration(seconds: 3),
                                      colorText: Colors.black,
                                      'Subscribe',
                                      'Subscribe to access this feature',
                                    );
                                  }
                                },
                              ),
                            if (_loggediN)
                              _buildFeatureTile(
                                Icons.account_circle_outlined,
                                'Profile',
                                isSmallScreen: isSmallScreen,
                                onTap: () {
                                  Get.toNamed('/profile');
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (!_loggediN || (_loggediN && !_isSubscribed))
                    _buildSubscribeCard(
                        themeColor, isSmallScreen, buttonFontSize),
                  SizedBox(height: isSmallScreen ? 8 : 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: launchUrlExample,
                    icon: const Icon(
                      Icons.sports_football,
                      color: Colors.black,
                    ),
                    label: Text(
                      'Learn More',
                      style: GoogleFonts.orbitron(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
    IconData icon,
    String title, {
    required bool isSmallScreen,
    Function()? onTap,
  }) {
    final double iconSize = isSmallScreen ? 32 : 40;
    final double fontSize = isSmallScreen ? 12 : 14;

    return ScaleTransition(
      scale: _fadeAnimation,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF9CFF33), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9CFF33).withOpacity(0.15),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: const Color(0xFF9CFF33),
              ),
              SizedBox(height: isSmallScreen ? 4 : 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  title,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscribeCard(
      Color themeColor, bool isSmallScreen, double buttonFontSize) {
    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 4 : 8),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
        gradient: LinearGradient(
          colors: [themeColor.withOpacity(0.7), themeColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: isSmallScreen ? 40 : 50,
            color: Colors.white,
          ),
          SizedBox(height: isSmallScreen ? 12 : 20),
          Text(
            _loggediN
                ? 'Activate Your Subscription'
                : 'Unlock the Power of GPT BETS AI',
            style: GoogleFonts.orbitron(
              fontSize: isSmallScreen ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 12 : 20),
          Text(
            _loggediN
                ? 'Subscribe to access premium features and insights!'
                : 'Subscribe now to access exclusive features and insights!',
            style: GoogleFonts.roboto(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          ScaleTransition(
            scale: _fadeAnimation,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.toNamed('/sub');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 30 : 40,
                  vertical: isSmallScreen ? 12 : 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
              ),
              icon: Icon(
                Icons.lock_open,
                color: themeColor,
                size: isSmallScreen ? 20 : 24,
              ),
              label: Text(
                'Subscribe Now',
                style: GoogleFonts.orbitron(
                  fontSize: buttonFontSize,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF9CFF33),
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 18 : 20,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
                color: Colors.white, fontSize: isSmallScreen ? 14 : 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'No',
                style: TextStyle(
                    color: Colors.grey, fontSize: isSmallScreen ? 14 : 16),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout(context);
              },
              child: Text(
                'Yes',
                style: TextStyle(
                    color: const Color(0xFF9CFF33),
                    fontSize: isSmallScreen ? 14 : 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        ModalRoute.withName(''),
      );
    } catch (e) {
      print('Logout error: $e');
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
