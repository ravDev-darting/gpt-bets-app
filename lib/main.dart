import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gptbets_sai_app/chatScreen.dart';
import 'package:gptbets_sai_app/gptBetsAssistant.dart';
import 'package:gptbets_sai_app/homeSc.dart';
import 'package:gptbets_sai_app/loginPage.dart';
import 'package:gptbets_sai_app/profileSc.dart';
import 'package:gptbets_sai_app/signUpPage.dart';
import 'package:gptbets_sai_app/splash.dart';
import 'package:gptbets_sai_app/sportsHub.dart';
import 'package:gptbets_sai_app/sub2.dart';
import 'package:gptbets_sai_app/subScreen.dart';

final String key = '02fe6e8734f74f7547654e87da0ac7e4';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreenMain()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignUpScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/sub', page: () => const Subscreen()),
        GetPage(name: '/sportsHub', page: () => const Sportshub()),
        GetPage(name: '/chat', page: () => const ChatScreen()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
        GetPage(name: '/chatBot', page: () => const ChatbotScreen()),
        GetPage(name: '/sub2', page: () => const SubscriptionScreen()),
      ],
    );
  }
}
