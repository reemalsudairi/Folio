import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/Signup.dart';
import 'package:folio/screens/homePage.dart';

import 'ResetPasswordPage.dart'; // Import the reset password page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEmailValid = true;
  bool _obscurePassword = true; // To toggle password visibility

  @override
  void initState() {
    super.initState();
    emailController.addListener(() {
      setState(() {
        _isEmailValid = _validateEmail(emailController.text);
      });
    });
  }

  Future<void> signUserIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus(); // Dismiss keyboard
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        Navigator.pop(context); // Dismiss loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const HomePage(
                    userId: '',
                  )), // Ensure HomePage is the correct widget
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Login Successful!"),
              backgroundColor: Colors.green),
        );
      } on FirebaseAuthException catch (e) {
        Navigator.pop(context); // Dismiss loading dialog on error
        String errorMessage = _handleAuthError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      } catch (e) {
        Navigator.pop(context); // Dismiss loading dialog on error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("An unexpected error occurred."),
              backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter a valid email and password."),
            backgroundColor: Colors.red),
      );
    }
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
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
    bool isPassword = false,
  }) {
    return Container(
      width: 410, // Match the width of the fields on the SignUp page
      height: 50, // Match the height of the fields on the SignUp page
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
            color: const Color(0xFFF790AD),
            width: 2), // Default border thickness
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 8.0, horizontal: 20.0), // Adjusted padding
        child: TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : obscureText,
          cursorColor: const Color(0xFFF790AD), // Pink cursor color
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF9B9B9B)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
          ),
          validator: validator,
        ),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      "assets/images/Logo.png",
                      width: 500,
                      height: 300,
                      fit: BoxFit.cover,
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
                _buildTextField(
                  controller: emailController,
                  hintText: 'Email',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email.';
                    } else if (!_isEmailValid) {
                      return 'Invalid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResetPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Color(0xFF695555),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 410, // Match the width of the fields
                  height: 50, // Match the height of the fields
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF790AD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    onPressed: signUserIn,
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUp(),
                      ),
                    );
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Color(0xFF695555)),
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: TextStyle(
                            color: Color(0xFFF790AD),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
