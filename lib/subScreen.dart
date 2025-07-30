import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gptbets_sai_app/homeSc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:gptbets_sai_app/signUpPage.dart';

class Subscreen extends StatefulWidget {
  const Subscreen({super.key});

  @override
  State<Subscreen> createState() => _SubscreenState();
}

class _SubscreenState extends State<Subscreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
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

    const Set<String> productIds = {
      'weekly_plan',
      'monthly_plan',
      'yearly_plan',
    };

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds);

    print("Product details: ${response.productDetails.map((e) => e.id)}");
    print("Not found IDs: ${response.notFoundIDs}");

    setState(() {
      _isAvailable = isAvailable;
      _products = response.productDetails;
      _loading = false;
    });
  }

  Future<void> _handleBuyNow(BuildContext context, String productId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _promptLogin(context);
      return;
    }

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () {
        _showSnackBar('Product not found: $productId');
        throw Exception('Product not found: $productId');
      },
    );

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    // Temporarily listen only for this specific purchase
    late final StreamSubscription<List<PurchaseDetails>> subscription;

    subscription =
        _inAppPurchase.purchaseStream.listen((purchaseDetailsList) async {
      for (var purchaseDetails in purchaseDetailsList) {
        if (purchaseDetails.productID != productId) continue;

        if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }

          DateTime purchaseDate = DateTime.now();
          DateTime expiryDate;

          switch (purchaseDetails.productID) {
            case 'weekly_plan':
              expiryDate = purchaseDate.add(Duration(days: 7));
              break;
            case 'monthly_plan':
              expiryDate = DateTime(
                  purchaseDate.year, purchaseDate.month + 1, purchaseDate.day);
              break;
            case 'yearly_plan':
              expiryDate = DateTime(
                  purchaseDate.year + 1, purchaseDate.month, purchaseDate.day);
              break;
            default:
              expiryDate = purchaseDate;
          }

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

          _showSnackBar('Purchase successful: ${purchaseDetails.productID}');
          await subscription.cancel();

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
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          _showSnackBar('Error: ${purchaseDetails.error?.message}');
          await subscription.cancel();
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          _showSnackBar('Purchase canceled');
          await subscription.cancel();
        }
      }
    });

    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _showSnackBar("Purchase failed: $e");
      await subscription.cancel();
    }
  }

  void _promptLogin(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Authentication Required',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CFF33),
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
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF9CFF33),
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
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      'GPTBETS Assistant Model.',
      'GPTBETS Prediction Model.',
      'Live Odds and insights across all Bookmakers.',
      'Automatic Feature Updates when new versions become available.',
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios, color: Colors.white)),
          title: Text('Subscription Plans',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          backgroundColor: Color(0xFF9CFF33),
          centerTitle: true,
          elevation: 5,
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator())
            : !_isAvailable
                ? Center(
                    child: Text(
                      'In-app purchases are not available',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        PlanCard(
                          title: 'Weekly Plan',
                          price: '\$9.00',
                          productId: 'weekly_plan',
                          features: features,
                          buttonText: 'BUY NOW',
                          products: _products,
                          onBuy: _handleBuyNow,
                        ),
                        SizedBox(height: 16),
                        PlanCard(
                          title: 'Monthly Plan',
                          price: '\$30.00',
                          productId: 'monthly_plan',
                          features: features,
                          buttonText: 'BUY NOW',
                          products: _products,
                          onBuy: _handleBuyNow,
                        ),
                        SizedBox(height: 16),
                        PlanCard(
                          title: 'Yearly Plan',
                          price: '\$250.00',
                          productId: 'yearly_plan',
                          features: features,
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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9CFF33).withOpacity(0.15), Colors.white],
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
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9CFF33))),
              SizedBox(height: 8),
              Text(price,
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Color(0xFF388E3C),
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Color(0xFF9CFF33), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(feature,
                              style: GoogleFonts.poppins(
                                  fontSize: 16, color: Colors.black87)),
                        ),
                      ],
                    ),
                  )),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => onBuy(context, productId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF9CFF33),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                  child: Text(buttonText,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
