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

  // New fields
  bool _initializingPastPurchases = true;
  String? _pendingUserPurchaseId;

  @override
  void initState() {
    super.initState();
    _initializeInAppPurchase();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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

    // Start listening to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('[IAP] purchase stream error: $error'),
    );

    // FIRST: query past purchases and persist them quietly (no UI navigation)
    try {
      final past = await _inAppPurchase.queryPastPurchases();
      debugPrint('[IAP] past purchases count=${past.pastPurchases.length}');
      for (final pastPurchase in past.pastPurchases) {
        try {
          // Persist using productID + transaction info
          await _persistSubscriptionFromPastPurchase(pastPurchase);
          debugPrint('[IAP] persisted past purchase ${pastPurchase.productID}');
        } catch (e) {
          debugPrint('[IAP] error persisting past purchase ${pastPurchase.productID}: $e');
        }

        // Attempt to finish if needed. Some plugin versions accept PastPurchaseDetails here.
        try {
          if (pastPurchase.pendingCompletePurchase ?? false) {
            // convert to PurchaseDetails if needed (some plugin versions allow passing PastPurchaseDetails)
            final pd = PurchaseDetails(
              purchaseID: pastPurchase.purchaseID,
              productID: pastPurchase.productID,
              status: pastPurchase.status,
              transactionDate: pastPurchase.transactionDate,
              verificationData: pastPurchase.verificationData,
            );
            await _inAppPurchase.completePurchase(pd);
            debugPrint('[IAP] completed pending past purchase ${pastPurchase.productID}');
          }
        } catch (e) {
          debugPrint('[IAP] could not complete past purchase: $e');
        }
      }
    } catch (e) {
      debugPrint('[IAP] queryPastPurchases failed: $e');
    } finally {
      // mark that initial past purchases processing is complete
      _initializingPastPurchases = false;
    }

    // THEN: fetch product details for UI
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

  /// Handles incoming purchase updates
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    debugPrint('[IAP] purchase update: ${purchaseDetailsList.length} item(s)');
    final user = FirebaseAuth.instance.currentUser;

    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint('[IAP] update: id=${purchaseDetails.productID} status=${purchaseDetails.status}');
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _showSnackBar('Purchase is pending...');
          break;

        case PurchaseStatus.error:
          _showSnackBar('Purchase error: ${purchaseDetails.error?.message ?? 'unknown'}');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            final verified = await _verifyPurchase(purchaseDetails);
            if (!verified) {
              _showSnackBar('Purchase verification failed');
            } else {
              // persist subscription always (to handle restores & past purchases)
              await _persistSubscriptionToFirestore(purchaseDetails, user);

              // finish transaction so store doesn't re-deliver
              if (purchaseDetails.pendingCompletePurchase) {
                try {
                  await _inAppPurchase.completePurchase(purchaseDetails);
                  debugPrint('[IAP] completePurchase called for ${purchaseDetails.productID}');
                } catch (e) {
                  debugPrint('[IAP] completePurchase failed: $e');
                }
              }

              // Navigate only when this was a user-initiated purchase (pending id matches)
              final isUserInitiated = !_initializingPastPurchases &&
                  _pendingUserPurchaseId != null &&
                  _pendingUserPurchaseId == purchaseDetails.productID;

              if (isUserInitiated && mounted) {
                _pendingUserPurchaseId = null;
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
              } else {
                debugPrint('[IAP] purchase persisted but no navigation (initializingPast=$_initializingPastPurchases, pendingId=$_pendingUserPurchaseId)');
              }
            }
          } catch (e) {
            debugPrint('[IAP] error handling purchased/restored: $e');
            _showSnackBar('Error delivering purchase: $e');
            if (purchaseDetails.pendingCompletePurchase) {
              try {
                await _inAppPurchase.completePurchase(purchaseDetails);
              } catch (e2) {
                debugPrint('[IAP] completePurchase fallback failed: $e2');
              }
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

  /// Local (basic) verification placeholder. Replace with server-side validation for production.
  Future<bool> _verifyPurchase(PurchaseDetails p) async {
    debugPrint('[IAP] verifying ${p.productID} locally');
    // For TestFlight / sandbox we accept purchased/restored as valid.
    return p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored;
  }

  /// Persist subscription info for a PurchaseDetails object
  Future<void> _persistSubscriptionToFirestore(PurchaseDetails purchaseDetails, User? user) async {
    if (user == null) {
      debugPrint('[IAP] persist skipped: no authenticated user');
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

    debugPrint('[IAP] subscription written for ${user.uid}: ${purchaseDetails.productID} -> $expiryDate');
  }

  /// Persist subscription from PastPurchaseDetails (returned by queryPastPurchases)
  Future<void> _persistSubscriptionFromPastPurchase(PastPurchaseDetails past, [User? user]) async {
    user ??= FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[IAP] persistPast skipped: no authenticated user');
      return;
    }

    final DateTime purchaseDate = DateTime.now();
    late final DateTime expiryDate;

    final pid = past.productID ?? '';

    switch (pid) {
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
        'productId': pid,
        'status': 'active',
        'purchaseDate': purchaseDate,
        'expiryDate': expiryDate,
        'isActive': true,
      },
    }, SetOptions(merge: true));
  }

  /// Safe product lookup
  ProductDetails? _findProduct(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Initiate purchase and mark as user-initiated
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

    // mark this as user-initiated so listener can navigate after success
    _pendingUserPurchaseId = productId;

    // safety: clear pending flag after 60s in case store doesn't respond
    Future.delayed(const Duration(seconds: 60), () {
      if (_pendingUserPurchaseId == productId) {
        _pendingUserPurchaseId = null;
      }
    });

    try {
      // For subscriptions we call buyNonConsumable on both platforms
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('[IAP] buyNonConsumable invoked for $productId');
    } catch (e) {
      debugPrint('[IAP] purchase invocation error: $e');
      _showSnackBar('Failed to start purchase: $e');
      _pendingUserPurchaseId = null;
    }
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Authentication Required', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF9CFF33))),
        content: Text('Please register or log in to purchase a subscription.', style: GoogleFonts.poppins(fontSize: 16)),
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
