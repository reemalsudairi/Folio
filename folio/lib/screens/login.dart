import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ResetPasswordPage.dart';
import 'Signup.dart';
import 'first.page.dart';
import 'homePage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  final bool _obscurePassword = true;
  bool _isPasswordFieldValid = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Adding listeners to validate when the user leaves the fields
    emailFocusNode.addListener(() {
      if (!emailFocusNode.hasFocus) {
        _formKey.currentState?.validate();
      }
    });

    passwordFocusNode.addListener(() {
      if (!passwordFocusNode.hasFocus) {
        _validatePasswordField();
        _formKey.currentState
            ?.validate(); // Trigger validation when focus is lost
      }
    });
  }

  @override
  void dispose() {
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _validatePasswordField() {
    setState(() {
      _isPasswordFieldValid = passwordController.text.isNotEmpty &&
          passwordController.text.trim().length >= 6 &&
          passwordController.text.trim().length <= 16;
    });
  }

  Future<void> signUserIn() async {
    if (_formKey.currentState?.validate() ?? false && _isPasswordFieldValid) {
      FocusScope.of(context).unfocus();

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        Navigator.pop(context); // Remove loading dialog

        setState(() {
          _errorMessage = null;
        });

        _showConfirmationMessage(); // Show login confirmation

        // Delay navigation AFTER confirmation dialog is shown and closed
        Future.delayed(const Duration(seconds: 2), () {
          // Close confirmation dialog and navigate to the home page
          Navigator.pop(context); // Close the confirmation dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomePage(userId: userCredential.user?.uid ?? ''),
            ),
          );
        });
      } on FirebaseAuthException catch (e) {
        Navigator.pop(context); // Remove loading dialog on error

        setState(() {
          _errorMessage = _handleAuthError(e);
        });
      } catch (e) {
        Navigator.pop(context);

        setState(() {
          _errorMessage = "An unexpected error occurred.";
        });
      }
    } else {
      setState(() {
        _errorMessage = "Please fill in all fields correctly.";
      });
    }
  }

  void _showConfirmationMessage() {
    showDialog(
      context: context,
      barrierDismissible: false, // Disable dismissal by clicking outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.lightGreen.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                'Login Successful!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    // Automatically close the confirmation dialog after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close the confirmation dialog
    });
  }

  String _handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      /* case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is badly formatted.';*/
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'network-request-failed':
        return 'Network error, please try again later.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      default:
        return 'Invalid email/password. Please try again.';
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    required String? Function(String?) validator,
    Widget? suffixIcon,
    FocusNode? focusNode,
    int? maxLength,
    bool isValid = true,
    bool isPassword = false,
  }) {
    return SizedBox(
      width: 350,
      child: Column(
        children: [
          TextFormField(
            controller: controller,
            obscureText: obscureText ? _obscurePassword : false,
            cursorColor: const Color(0xFFF790AD),
            validator: validator,
            focusNode: focusNode,
            maxLength: maxLength,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')), // Prevent spaces
            ],
            onChanged: (value) {
              if (isPassword) {
                _validatePasswordField(); // Validate password when user types
              }
              setState(() {}); // Trigger UI update to remove error when fixed
            },
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
              counterText:
                  '${controller.text.length}/$maxLength', // Show character count
              counterStyle:
                  const TextStyle(color: Color(0xFF695555), fontSize: 12),
              suffixIcon: suffixIcon,
              //errorText: !isValid ? "Please enter a valid $hintText." : null,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 15, horizontal: 20), // Adjust padding
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Image.asset(
                        "assets/images/Logo.png",
                        width: 500,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        iconSize: 40,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const WelcomePage()),
                          );
                        },
                      ),
                    ),
                    const Positioned(
                      bottom: 10,
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
                const SizedBox(height: 20),

                // Red rectangle for error messages
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

                _buildTextField(
                  controller: emailController,
                  hintText: 'Email',
                  focusNode: emailFocusNode,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter an email.";
                    }

                    // Check for valid email format using regex
                    if (!RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(com|net|org|edu|gov|mil|info)$')
                        .hasMatch(value.trim())) {
                      return "Please enter a valid email."; // Specific error message
                    }
                    return null; // Return null if valid
                  },
                  maxLength: 254,
                  isValid: _formKey.currentState?.validate() ?? true,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  focusNode: passwordFocusNode,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter a password.";
                    }
                    return null; // Return null if valid
                  },
                  maxLength: 16,
                  isValid: _isPasswordFieldValid,
                  isPassword: true,
                ),
                const SizedBox(
                    height: 5), // Space between password field and link
                Align(
                  alignment: Alignment.centerLeft, // Align to the left
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ResetPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Color(0xFFF790AD)),
                    ),
                  ),
                ),
                const SizedBox(height: 10), // Space before the login button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF790AD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    minimumSize: const Size(350, 50), // Width and height
                  ),
                  onPressed: signUserIn,
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUp()),
                        );
                      },
                      child: const Text(
                        'Sign up',
                        style: TextStyle(color: Color(0xFFF790AD)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
