// lib/subScreen.dart
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:gptbets_sai_app/homeSc.dart';
import 'package:gptbets_sai_app/signUpPage.dart';

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
    debugPrint('[IAP] initializing...');
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      setState(() {
        _isAvailable = false;
        _loading = false;
      });
      debugPrint('[IAP] not available on device');
      return;
    }

    // Important: keep the listener active while the app runs.
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('[IAP] purchase stream error: $error'),
    );

    const productIds = {
      'weekly_plan_v6',
      'monthly_plan_v6',
      'yearly_plan_v6',
    };

    final response = await _inAppPurchase.queryProductDetails(productIds);
    debugPrint('[IAP] product query complete. found: ${response.productDetails.map((p) => p.id).toList()}');
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[IAP] Products not found: ${response.notFoundIDs}');
    }

    setState(() {
      _isAvailable = available;
      _products = response.productDetails;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Purchase stream handler
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    debugPrint('[IAP] purchase update: ${purchaseDetailsList.length} items');
    final user = FirebaseAuth.instance.currentUser;

    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint('[IAP] status=${purchaseDetails.status} id=${purchaseDetails.productID}');
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _showSnackBar('Purchase is pending...');
          break;

        case PurchaseStatus.error:
          _showSnackBar('Purchase error: ${purchaseDetails.error?.message ?? 'unknown'}');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // handle both purchased and restored
          try {
            // Basic verification placeholder (recommended: server-side validation)
            final verified = await _verifyPurchase(purchaseDetails);
            if (!verified) {
              _showSnackBar('Purchase verification failed');
            } else {
              // persist subscription
              await _persistSubscriptionToFirestore(purchaseDetails, user);

              // complete the transaction so the store doesn't deliver it again
              if (purchaseDetails.pendingCompletePurchase) {
                debugPrint('[IAP] completing purchase for ${purchaseDetails.productID}');
                await _inAppPurchase.completePurchase(purchaseDetails);
              }

              // navigate after persistence & completion
              if (mounted) {
                _showSnackBar('Purchase successful!');
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 600),
                  ),
                  (route) => false,
                );
              }
            }
          } catch (e) {
            debugPrint('[IAP] error handling purchased/restored: $e');
            _showSnackBar('Error delivering purchase: $e');
            // still attempt to complete to avoid duplicate
            if (purchaseDetails.pendingCompletePurchase) {
              await _inAppPurchase.completePurchase(purchaseDetails);
            }
          }
          break;

        case PurchaseStatus.canceled:
          _showSnackBar('Purchase canceled');
          break;

        default:
          break;
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails p) async {
    // IMPORTANT: This is a placeholder. Implement server-side receipt validation for production.
    // For sandbox/TestFlight testing, we just check that status == purchased.
    debugPrint('[IAP] verifying ${p.productID} (local check)');
    return p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored;
  }

  Future<void> _persistSubscriptionToFirestore(PurchaseDetails purchaseDetails, User? user) async {
    if (user == null) {
      debugPrint('[IAP] No user - cannot persist subscription');
      return;
    }

    final DateTime purchaseDate = DateTime.now();
    late final DateTime expiryDate;

    switch (purchaseDetails.productID) {
      case 'weekly_plan_v6':
        expiryDate = purchaseDate.add(const Duration(days: 7));
        break;
      case 'monthly_plan_v6':
        expiryDate = DateTime(purchaseDate.year, purchaseDate.month + 1, purchaseDate.day);
        break;
      case 'yearly_plan_v6':
        expiryDate = DateTime(purchaseDate.year + 1, purchaseDate.month, purchaseDate.day);
        break;
      default:
        expiryDate = purchaseDate;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'subscription': {
        'productId': purchaseDetails.productID,
        'status': 'active',
        'purchaseDate': purchaseDate,
        'expiryDate': expiryDate,
        'isActive': true,
      },
    }, SetOptions(merge: true));

    debugPrint('[IAP] persisted subscription for ${user.uid}: ${purchaseDetails.productID} -> $expiryDate');
  }

  /// safe product lookup
  ProductDetails? _findProduct(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Initiates purchase flow (safe)
  void _handleBuyNow(BuildContext context, String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog(context);
      return;
    }

    final product = _findProduct(productId);
    if (product == null) {
      _showSnackBar('Product not available yet - please wait and try again.');
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    // For subscriptions use buyNonConsumable on both platforms.
    // buyConsumable is intended for single-use consumables.
    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('[IAP] buyNonConsumable invoked for $productId');
    } catch (e) {
      debugPrint('[IAP] purchase invocation error: $e');
      _showSnackBar('Failed to start purchase: $e');
    }
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignUpScreen()), (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9CFF33)),
            child: Text('Register Yourself', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
          title: Text('Subscription Plans', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
          backgroundColor: const Color(0xFF9CFF33),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : !_isAvailable
                ? Center(child: Text('In-app purchases are not available', style: GoogleFonts.poppins(color: Colors.white)))
                : Container(
                    color: Colors.black,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          PlanCard(
                            title: 'Weekly Plan',
                            productId: 'weekly_plan_v6',
                            staticPrice: '\$9.00',
                            features: const [
                              'GPTBETS Assistant Model.',
                              'GPTBETS Prediction Model.',
                              'Live Odds and insights across all Bookmakers.',
                              'Automatic Feature Updates when new versions become available.',
                            ],
                            buttonText: 'BUY NOW',
                            products: _products,
                            onBuy: _handleBuyNow,
                          ),
                          const SizedBox(height: 16),
                          PlanCard(
                            title: 'Monthly Plan',
                            productId: 'monthly_plan_v6',
                            staticPrice: '\$30.00',
                            features: const [
                              'GPTBETS Assistant Model.',
                              'GPTBETS Prediction Model.',
                              'Live Odds and insights across all Bookmakers.',
                              'Automatic Feature Updates when new versions become available.',
                            ],
                            buttonText: 'BUY NOW',
                            products: _products,
                            onBuy: _handleBuyNow,
                          ),
                          const SizedBox(height: 16),
                          PlanCard(
                            title: 'Yearly Plan',
                            productId: 'yearly_plan_v6',
                            staticPrice: '\$250.00 Per Year',
                            features: const [
                              'GPTBETS Assistant Model.',
                              'GPTBETS Prediction Model.',
                              'Live Odds and insights across all Bookmakers.',
                              'Automatic Feature Updates when new versions become available.',
                            ],
                            buttonText: 'BUY NOW',
                            products: _products,
                            onBuy: _handleBuyNow,
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  final String title;
  final String productId;
  final String staticPrice;
  final List<String> features;
  final String buttonText;
  final List<ProductDetails> products;
  final Function(BuildContext, String) onBuy;

  const PlanCard({
    super.key,
    required this.title,
    required this.productId,
    required this.staticPrice,
    required this.features,
    required this.buttonText,
    required this.products,
    required this.onBuy,
  });

  ProductDetails? _find(List<ProductDetails> list, String id) {
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _find(products, productId);
    final priceText = product?.price ?? staticPrice;
    final isAvailable = product != null;

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFF9CFF33).withOpacity(0.15), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF9CFF33))),
            const SizedBox(height: 8),
            Text(priceText, style: GoogleFonts.poppins(fontSize: 20, color: const Color(0xFF388E3C), fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                  const Icon(Icons.check_circle, color: Color(0xFF9CFF33), size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(feature, style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87))),
                ]))),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: isAvailable ? () => onBuy(context, productId) : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9CFF33), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 6),
                child: Text(buttonText, style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            if (!isAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(child: Text('Loading price...', style: GoogleFonts.poppins(color: Colors.grey))),
              ),
          ]),
        ),
      ),
    );
  }
}
