//flutter run -d chrome --target=lib/admin_main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:folio/admin_screens/AdminLoginPage.dart'; // Ensure this path is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDI7_Yop7ZAf_4k8k4je_EkMGoHBupHnb0",
      appId: "1:866432989267:android:57f897cf2489c0a5d56ea6",
      messagingSenderId: "866432989267",
      projectId: "folio-29339",
    ),
  );
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF790AD)),
        useMaterial3: true,
        fontFamily: 'YoungSerif-Regular'
      ),
      home: AdminLoginPage(), // Change this line if necessary
    );
  }
}