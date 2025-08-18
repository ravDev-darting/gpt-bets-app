import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gptbets_sai_app/homeSc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  bool _available = true;
  List<ProductDetails> _products = [];
  bool _isLoading = true;

  final List<String> _productIds = [
    'weekly_plan_v6',
    'monthly_plan_v6',
    'yearly_plan_v6',
  ];

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  void _initStore() async {
    _available = await _inAppPurchase.isAvailable();
    if (_available) {
      ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(_productIds.toSet());
      setState(() {
        _products = response.productDetails;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }

    _inAppPurchase.purchaseStream.listen(_listenToPurchaseUpdated);
  }

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        await _verifyAndSavePurchase(purchaseDetails);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Purchase Error: ${purchaseDetails.error?.message}')),
        );
      }
    }
  }

  Future<void> _verifyAndSavePurchase(PurchaseDetails purchaseDetails) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Example: setting expiry dates based on plan
    DateTime purchaseDate = DateTime.now();
    DateTime expiryDate;

    switch (purchaseDetails.productID) {
      case 'weekly_plan_v6':
        expiryDate = purchaseDate.add(const Duration(days: 7));
        break;
      case 'monthly_plan_v6':
        expiryDate = purchaseDate.add(const Duration(days: 30));
        break;
      case 'yearly_plan_v6':
        expiryDate = purchaseDate.add(const Duration(days: 365));
        break;
      default:
        expiryDate = purchaseDate;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'subscription': {
        'productId': purchaseDetails.productID,
        'status': 'active',
        'purchaseDate': DateFormat('yyyy-MM-dd').format(purchaseDate),
        'expiryDate': DateFormat('yyyy-MM-dd').format(expiryDate),
        'isActive': true,
      },
    }, SetOptions(merge: true));
  }

  void _buyProduct(ProductDetails productDetails) {
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    if (Platform.isIOS) {
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      _inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam, autoConsume: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_available) {
      return const Scaffold(
        body: Center(child: Text('In-App Purchases not available')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Plan')),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(product.title),
              subtitle: Text(product.description),
              trailing: TextButton(
                onPressed: () => _buyProduct(product),
                child:
                    Text(product.price, style: const TextStyle(fontSize: 16)),
              ),
            ),
          );
        },
      ),
    );
  }
}
