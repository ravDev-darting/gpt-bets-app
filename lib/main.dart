import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gptbets_sai_app/chatScreen.dart';
import 'package:gptbets_sai_app/homeSc.dart';
import 'package:gptbets_sai_app/loginPage.dart';
import 'package:gptbets_sai_app/signUpPage.dart';
import 'package:gptbets_sai_app/splash.dart';
import 'package:gptbets_sai_app/sportsHub.dart';
import 'package:gptbets_sai_app/sportsPage.dart';
import 'package:gptbets_sai_app/subScreen.dart';

final String key = 'c53e274ad03bab6946c82d64a252883a';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        getPages: [
          GetPage(name: '/splash', page: () => SplashScreenMain()),
          GetPage(name: '/login', page: () => LoginScreen()),
          GetPage(name: '/signup', page: () => SignUpScreen()),
          GetPage(name: '/home', page: () => HomeScreen()),
          GetPage(name: '/sub', page: () => Subscreen()),
          GetPage(name: '/sportsHub', page: () => Sportshub()),
          GetPage(name: '/chat', page: () => ChatScreen()),
        ],
      ),
    );
  }
}
