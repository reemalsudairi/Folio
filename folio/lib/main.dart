import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/homePage.dart';
import 'package:folio/screens/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyD08AQh_ozf3QSFAZcg7eTWGtBMJw_kG_0",
      appId: "1:866432989267:android:57f897cf2489c0a5d56ea6",
      messagingSenderId: "866432989267",
      projectId: "folio-29339",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? user;

    @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF790AD)),
        useMaterial3: true,
      ),
      home: user != null ? HomePage(userId: user!.uid) : Splash() , // Set SignUp as the home page
    );
  }
}
