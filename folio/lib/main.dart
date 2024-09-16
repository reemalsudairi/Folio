import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF790AD)),
        useMaterial3: true,
      ),
      home: Splash(), // Set SignUp as the home page
    );
  }
}
