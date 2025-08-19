import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gptbets_sai_app/homeSc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:gptbets_sai_app/signUpPage.dart';
import 'dart:async';
import 'dart:io';

class Subscreen extends StatefulWidget {
  const Subscreen({super.key});

  @override
  State<Subscreen> createState() => _SubscreenState();
}

class _SubscreenState extends State<Subscreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeInAppPurchase();
  }

  Future<void> _initializeInAppPurchase() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = false;
        _loading = false;
      });
      return;
    }

    // Listen globally for purchases
    _subscription = _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('Purchase stream error: $error'),
    );

    // Fetch product details
    const Set<String> productIds = {
      'weekly_plan_v6',
      'monthly_plan_v6',
      'yearly_plan_v6',
    };
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds);
    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }

    setState(() {
      _isAvailable = isAvailable;
      _products = response.productDetails;
      _loading = false;
    });
  }

  /// Handle purchase updates
  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    final user = FirebaseAuth.instance.currentUser;

    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _showSnackBar('Purchase is pending...');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _showSnackBar('Purchase error: ${purchaseDetails.error?.message}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        if (user != null) {
          DateTime purchaseDate = DateTime.now();
          DateTime expiryDate;

          switch (purchaseDetails.productID) {
            case 'weekly_plan_v6':
              expiryDate = purchaseDate.add(const Duration(days: 7));
              break;
            case 'monthly_plan_v6':
              expiryDate = DateTime(
                  purchaseDate.year, purchaseDate.month + 1, purchaseDate.day);
              break;
            case 'yearly_plan_v6':
              expiryDate = DateTime(
                  purchaseDate.year + 1, purchaseDate.month, purchaseDate.day);
              break;
            default:
              expiryDate = purchaseDate;
          }

          // Save to Firestore BEFORE consuming
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'subscription': {
              'productId': purchaseDetails.productID,
              'status': 'active',
              'purchaseDate': purchaseDate,
              'expiryDate': expiryDate,
              'isActive': true,
            },
          }, SetOptions(merge: true));

          _showSnackBar('Purchase successful!');

          // ✅ Complete purchase (consume it if Android consumable)
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }

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
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        _showSnackBar('Purchase canceled');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
          title: Text('Subscription Plans',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          backgroundColor: const Color(0xFF9CFF33),
          centerTitle: true,
          elevation: 5,
          shadowColor: Colors.black54,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : !_isAvailable
                ? Center(
                    child: Text(
                      'In-app purchases are not available',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        PlanCard(
                          title: 'Weekly Plan',
                          price: '\$9.00',
                          productId: 'weekly_plan_v6',
                          features: _features,
                          buttonText: 'BUY NOW',
                          products: _products,
                          onBuy: _handleBuyNow,
                        ),
                        const SizedBox(height: 16),
                        PlanCard(
                          title: 'Monthly Plan',
                          price: '\$30.00',
                          productId: 'monthly_plan_v6',
                          features: _features,
                          buttonText: 'BUY NOW',
                          products: _products,
                          onBuy: _handleBuyNow,
                        ),
                        const SizedBox(height: 16),
                        PlanCard(
                          title: 'Yearly Plan',
                          price: '\$250.00',
                          productId: 'yearly_plan_v6',
                          features: _features,
                          buttonText: 'BUY NOW',
                          products: _products,
                          onBuy: _handleBuyNow,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  void _handleBuyNow(BuildContext context, String productId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Prompt login/register
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Authentication Required',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9CFF33),
              ),
            ),
            content: Text(
              'Please register or log in to purchase a subscription.',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignUpScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9CFF33),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Register Yourself',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.white,
            elevation: 8,
          );
        },
      );
      return;
    }

    // Find the product
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    // Start purchase
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    if (Platform.isIOS) {
      await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } else {
      await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: false, // 🔑 save before consuming
      );
    }
  }

  final List<String> _features = [
    'GPTBETS Assistant Model.',
    'GPTBETS Prediction Model.',
    'Live Odds and insights across all Bookmakers.',
    'Automatic Feature Updates when new versions become available.',
  ];
}

class PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String productId;
  final List<String> features;
  final String buttonText;
  final List<ProductDetails> products;
  final Function(BuildContext, String) onBuy;

  const PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.productId,
    required this.features,
    required this.buttonText,
    required this.products,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black45,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF9CFF33).withOpacity(0.15), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9CFF33),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: const Color(0xFF388E3C),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF9CFF33), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => onBuy(context, productId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9CFF33),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                    shadowColor: Colors.black45,
                  ),
                  child: Text(
                    buttonText,
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
