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
      _showDialog('Error', 'In-App Purchases not available on this device.');
    }

    _inAppPurchase.purchaseStream.listen(_listenToPurchaseUpdated);
  }

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _showDialog('Pending', 'Your purchase is pending. Please wait...');
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        try {
          await _verifyAndSavePurchase(purchaseDetails);

          if (Platform.isAndroid) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }

          _showDialog('Success', 'Purchase successful! Navigating to Home...',
              onClose: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
            );
          });
        } catch (e) {
          _showDialog('Error', 'Purchase verification failed: $e');
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _showDialog(
            'Error', 'Purchase failed: ${purchaseDetails.error?.message}');
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        // Optionally handle restored subscriptions
        _showDialog('Restored', 'Previous purchase restored.');
      }
    }
  }

  Future<void> _verifyAndSavePurchase(PurchaseDetails purchaseDetails) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

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

  void _showDialog(String title, String message, {VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onClose != null) onClose();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
