import 'package:flutter/material.dart';
import 'package:folio/screens/Signup.dart';
import 'package:folio/screens/homePage.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3), // Background color
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Stack(
                alignment: Alignment.center, // Centers the stack content
                children: [
                  // Logo (Image)
                  Image.asset(
                    "assets/images/Logo.png",
                    width: 500,
                    height: 300,
                    fit: BoxFit
                        .cover, // Ensures the image fits within the container
                  ),

                  // Introductory text at the bottom of the image
                  const Positioned(
                    bottom:
                        10, // Position the text 10 pixels from the bottom of the image
                    left: 0,
                    right: 0,
                    child: Text(
                      "Explore, discuss, and enjoy books with a \ncommunity of passionate readers.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0XFF695555),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 22.08 / 16,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 48), // Space between text and buttons
            // Sign Up Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUp()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Button background color
                side: const BorderSide(color: Color(0xFFFFA1C9), width: 2), // Border color and width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 12),
              ),
              child: const Text(
                'Sign up',
                style: const TextStyle(
                  color: Color(0xFFFFA1C9), // Text color
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 16), // Space between buttons
            // Login Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA1C9), // Button background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 130, vertical: 12),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white, // Text color
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

