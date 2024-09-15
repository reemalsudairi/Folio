import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/Signup.dart';

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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SignUp(), // Set SignUp as the home page
    );
  }
}
