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

  bool _obscurePassword = true;

  bool _isPasswordFieldValid = true;

  String? _errorMessage; // Variable to hold error messages

  @override
  void initState() {
    super.initState();

    // Adding listeners to focus nodes to validate when user leaves the fields
    emailFocusNode.addListener(() {
      if (!emailFocusNode.hasFocus) {
        _formKey.currentState?.validate();
      }
    });

    passwordFocusNode.addListener(() {
      if (!passwordFocusNode.hasFocus) {
        _validatePasswordField(); // Validate password field only when focus is lost
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
      _isPasswordFieldValid =
          passwordController.text.isNotEmpty &&
          passwordController.text.trim().length <= 16;
    });
  }

  Future<void> signUserIn() async {
    if (_formKey.currentState?.validate() ?? false && _isPasswordFieldValid) {
      FocusScope.of(context).unfocus();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        Navigator.pop(context);

        setState(() {
          _errorMessage = null;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(userId: userCredential.user?.uid ?? '')),
        );
      } on FirebaseAuthException catch (e) {
        Navigator.pop(context);

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

  String _handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
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
  }) {
    return Container(
      width: 350,
      // Remove fixed height to avoid overflow issues
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
              setState(() {}); // Call setState to update the UI
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
              counterText: '${controller.text.length}/$maxLength', // Show character count
              counterStyle: const TextStyle(color: Color(0xFF695555), fontSize: 12),
              suffixIcon: suffixIcon,
              errorText: isValid ? null : "Please enter a password.",
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Adjust padding
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
                            MaterialPageRoute(builder: (context) => WelcomePage()),
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
                    if (value.trim().contains(' ')) {
                      return "Email cannot contain spaces.";
                    }
                    if (value.trim().length > 254) {
                      return "Email can't exceed 254 characters.";
                    }
                    if (!RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                        .hasMatch(value.trim())) {
                      return "Enter a valid email address.";
                    }
                    return null;
                  },
                  maxLength: 254,
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: true,
                      focusNode: passwordFocusNode,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        color: const Color(0xFFF790AD),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      maxLength: 16,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a password.";
                        }
                        if (value.trim().length < 6 || value.trim().length > 16) {
                          return "Password must be between 6 and 16 characters.";
                        }
                        return null;
                      },
                      isValid: _isPasswordFieldValid,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ResetPasswordPage()),
                        );
                      },
                      child: const Text(
                        "Forget Password?",
                        style: TextStyle(
                          color: Color(0xFFF790AD),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
  width: 350,
  height: 50, // Set the width to 350
  child: ElevatedButton(
    onPressed: signUserIn,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF790AD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    child: const Text(
      'Login',
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),
    ),
  ),
),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don''t have an account?',
                      style: TextStyle(
                        color: Color(0xFF695555),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUp()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFFF790AD),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

