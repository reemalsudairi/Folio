import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:folio/firebase_options.dart';
import 'package:folio/screens/splash.dart';
import 'package:folio/services/local.notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Use the default Firebase options generated by flutterfire_cli
  );
  //  tz.initializeTimeZones();
  await LocalNotificationService.init();
  // await requestNotificationPermission();

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
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFFF790AD)),
            useMaterial3: true,
            fontFamily: 'YoungSerif-Regular'),
        home:
            const Splash() // If user is logged in, show HomePage, otherwise show Splash screen
        );
  }
}

// // Request Notification Permission
// Future<void> requestNotificationPermission() async {
//   if (await Permission.notification.isGranted) {
//     debugPrint('Notification permission already granted.');
//     return;
//   }

//   final status = await Permission.notification.request();

//   if (status.isGranted) {
//     debugPrint('Notification permission granted.');
//   } else if (status.isDenied) {
//     debugPrint('Notification permission denied.');
//   } else if (status.isPermanentlyDenied) {
//     debugPrint('Notification permission permanently denied.');
//     await openAppSettings();
//   }
// }

