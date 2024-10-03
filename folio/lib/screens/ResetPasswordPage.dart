import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:folio/screens/login.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage; // To hold error messages for the container
  String? _inlineErrorMessage; // To hold inline error messages
  bool _isLoading = false;
  final FocusNode _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _emailFocusNode.dispose();
    emailController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(com|net|org|edu|gov|mil|info)$');
    return emailRegex.hasMatch(email);
  }

  void _showConfirmationMessage() {
    showDialog(
      context: context,
      barrierDismissible: true,
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
                'If the email exists, a reset link was sent!',
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

    // Automatically close the dialog after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  Future<void> sendPasswordResetEmail() async {
    setState(() {
      _errorMessage = null; // Clear previous error message
      _inlineErrorMessage = null; // Clear inline error messages
    });

    // Check if the email field is empty first
    if (emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage =
            "Email field cannot be empty."; // Set the error message for empty email
      });
      return; // Exit the function if the email is empty
    }

    // Proceed with email validation if it's not empty
    if (_validateEmail(emailController.text.trim())) {
      setState(() {
        _isLoading = true;
        _errorMessage = null; // Reset error message
        _inlineErrorMessage =
            null; // Clear inline error messages on valid submission
      });

      try {
        final String email = emailController.text.trim().toLowerCase();
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        // Show confirmation message
        _showConfirmationMessage();

        // Clear the email field

        // Clear error messages after successful reset link send
        setState(() {
          _errorMessage = null;
          _inlineErrorMessage = null;
        });
      } on FirebaseAuthException catch (e) {
        // Handle errors based on the exception code
        if (e.code == 'user-not-found') {
          setState(() {
            _errorMessage = "No user found for that email.";
            emailController.clear(); // Clear email input when there's an error
          });
        } else {
          setState(() {
            _errorMessage = "An error occurred, please try again.";
            emailController.clear(); // Clear email input when there's an error
          });
        }

        //
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = "Invalid email, please check the email format.";
        // emailController.clear(); // Clear email input on invalid format
      });

      // Clear error message after 1 second
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    Widget? suffixIcon,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          cursorColor: const Color(0xFFF790AD),
          focusNode: focusNode,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
            LengthLimitingTextInputFormatter(254), // Limit to 254 characters
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
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
          validator: (value) {
            // Moved error checks to the onChanged method
            if (value == null || value.isEmpty) {
              return 'Please enter an email.'; // For inline error
            } else if (!_validateEmail(value)) {
              return 'Please enter a valid email.'; // For inline error
            }
            return null; // No error
          },
          onChanged: (value) {
            // Clear inline error messages as the user types
            setState(() {
              _inlineErrorMessage = null;
            });
          },
        ),
        const SizedBox(height: 5),
        // Row for character count to align it on the right
        Row(
          mainAxisAlignment: MainAxisAlignment.end, // Align to the right
          children: [
            Text(
              '${controller.text.length} / 254',
              style: const TextStyle(
                color: Color(0xFF695555),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
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
                                builder: (context) => const LoginPage()),
                          );
                        },
                      ),
                    ),
                    const Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Text(
                        "Enter your email to reset your password.",
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

                // Container error message above the email field
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
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

                // Display inline error message below the email field if exists
                if (_inlineErrorMessage != null)
                  Text(
                    _inlineErrorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                const SizedBox(height: 10),

                // Email Text Field with SizedBox
                SizedBox(
                  width: 350, // Set this to match the button's width
                  child: _buildTextField(
                    controller: emailController,
                    hintText: 'Email',
                    focusNode: _emailFocusNode,
                    validator: (value) {
                      // Moved error checks to the onChanged method
                      return null; // No error; validation is handled in onChanged
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Submit button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF790AD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    minimumSize: const Size(350, 50), // Width and height
                  ),
                  onPressed: _isLoading ? null : sendPasswordResetEmail,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Reset Password',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                ),

                const SizedBox(height: 10),

                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Navigate back to login page
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: "Remember your password? ",
                      style: TextStyle(color: Color(0xFF695555)),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: Color(0xFFF790AD), // Match the link color
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
