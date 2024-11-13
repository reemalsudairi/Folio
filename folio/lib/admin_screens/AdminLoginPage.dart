import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin_dashboard.dart'; // Make sure to import your admin dashboard file

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage; // Add error message variable

  bool _obscurePassword = true;

  Future<void> signAdminIn() async {
  if (_formKey.currentState?.validate() ?? false) {
    FocusScope.of(context).unfocus();

    try {
      // Convert email to lowercase for case-insensitive comparison
      String email = emailController.text.trim().toLowerCase();
      String password = passwordController.text.trim();

      // Log the email and password being used for the login attempt
      print("Attempting to sign in with email: $email and password: $password");

      // Fetch the admin document from Firestore
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('admin')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      // Check if any admin document was found
      if (result.docs.isNotEmpty) {
        String adminUsername = result.docs.first['username'];
        // Admin found, navigate to the dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboard(adminUsername: adminUsername),
          ),
        );
      } else {
        // No admin found with the provided credentials
        setState(() {
          _errorMessage = 'Invalid email or password. Please try again.';
        });
      }
    } catch (e) {
      print("Unexpected error: $e"); // Log unexpected errors
      setState(() {
        _errorMessage = "An unexpected error occurred."; // Handle unexpected errors
      });
    }
  }
}


  String _handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'network-request-failed':
        return 'Network error, please try again later.';
      default:
        return 'Invalid email/password. Please try again.'; // Default error message
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    required String? Function(String?) validator,
    int? maxLength, // Add maxLength parameter
  }) {
    return SizedBox(
      width: 350,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText ? _obscurePassword : false,
        cursorColor: const Color(0xFFF790AD),
        validator: validator,
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'\s')),
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength), // Limit length if specified
        ],
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
              color: Color(0xFF695555),
              fontWeight: FontWeight.w400,
              fontSize: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: const BorderSide(color: Color(0xFFF790AD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: const BorderSide(color: Color(0xFFF790AD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: const BorderSide(color: Color(0xFFF790AD)),
          ),
          suffixIcon: obscureText
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: const Color(0xFFF790AD),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      body: Center( // Centering the body content
        child: SingleChildScrollView (
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Centering the column content
                crossAxisAlignment: CrossAxisAlignment.center, // Centering the content
                children: [
                  Image.asset(
                    "assets/images/Logo.png",
                    width: 500,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 1), // Reduced space between image and text
                  const Text(
                    'Admin Login', // Text to display
                    style: TextStyle(
                      fontSize: 24, // Font size
                      fontWeight: FontWeight.bold, // Bold text
                      color: Color(0xFF695555), // Text color
                    ),
                  ),
                  const SizedBox(height: 20), // Space between text and email field

                  // Display error message if exists
                  if (_errorMessage != null)
                    Container(
                      width: 350,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Email Field Title and Text Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align title to the left
                    children: [
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF695555),
                        ),
                      ),
                      const SizedBox(height: 5),
                      _buildTextField(
                        controller: emailController,
                        hintText: 'Email',
                        maxLength: 254, // Set the max length for the email
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Password Field Title and Text Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align title to the left
                    children: [
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF695555),
                        ),
                      ),
                      const SizedBox(height: 5),
                      _buildTextField(
                        controller: passwordController,
                        hintText: 'Password',
                        obscureText: true,
                        maxLength: 16, // Set the max length for the password
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Login Button
                  SizedBox(
                    width: 350,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF790AD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      onPressed: signAdminIn,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10), // Reduced vertical padding
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}