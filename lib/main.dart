import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gptbets_sai_app/chatScreen.dart';
import 'package:gptbets_sai_app/homeSc.dart';
import 'package:gptbets_sai_app/loginPage.dart';
import 'package:gptbets_sai_app/signUpPage.dart';
import 'package:gptbets_sai_app/splash.dart';
import 'package:gptbets_sai_app/sportsHub.dart';
import 'package:gptbets_sai_app/subScreen.dart';
import 'package:responsive_framework/responsive_framework.dart';

final String key = 'c53e274ad03bab6946c82d64a252883a';

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
      ],
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: Builder(
          builder: (context) {
            // Dynamically adjust reference width based on breakpoint
            double referenceWidth = 375; // Default mobile design width
            final breakpoints = ResponsiveBreakpoints.of(context);
            if (breakpoints.isMobile) {
              referenceWidth = 500;
            } else if (breakpoints.isTablet) {
              referenceWidth = 800;
            } else if (breakpoints.isDesktop) {
              referenceWidth = 1200;
            } else if (breakpoints.largerThan(DESKTOP)) {
              referenceWidth = 2460; // For 4K screens
            }

            return ResponsiveScaledBox(
              width: referenceWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: child!,
              ),
            );
          },
        ),
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1200, name: DESKTOP),
          const Breakpoint(start: 1201, end: 2460, name: '4K'),
        ],
      ),
    );
  }
}
