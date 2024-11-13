import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:folio/screens/first.page.dart';
import 'package:folio/screens/homePage.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  User? user;
  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    // Immersive mode to hide system UI during splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Navigate to SignUp page after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      user != null ? Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(userId: user!.uid)),
      ) : Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    });
  }

  @override
  void dispose() {
    // Restore system UI when leaving the splash screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3), // Set background color
      body: Center(
        // Center the logo in the middle
        child: Image.asset(
          "assets/images/Logo.png", // Path to logo asset
          width: 500, // Set logo width
          height: 500, // Set logo height
        ),
      ),
    );
  }
}