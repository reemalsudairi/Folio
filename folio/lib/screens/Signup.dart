// ignore_for_file: prefer_const_constructors

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/homePage.dart';
import 'package:folio/screens/ProfileSetup.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart';     // Firebase Auth


class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F3),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 36),

              // Back icon
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () {
                    print("Back button pressed");
                  },
                  iconSize: 50,
                  icon: Icon(Icons.arrow_back_ios),
                ),
              ),

              Stack(
                alignment: Alignment.center, // Centers the stack content
                children: [
                  // Logo (Image)
                  Image.asset(
                    "images/Logo.png",
                    width: 500,
                    height: 300,
                    fit: BoxFit.cover, // Ensures the image fits within the container
                  ),

                  // Introductory text at the bottom of the image
                  Positioned(
                    bottom: 10, // Position the text 10 pixels from the bottom of the image
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

              SizedBox(height: 20),

              // Form fields
              Container(
                width: 410,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 20),

                      // Username
                      TextFormField(
                        autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "The username field is empty";
                          }
                          if (value.length < 3) {
                            return "Username can't be less than 3 characters";
                          }
                          RegExp usernamePattern = RegExp(r'^[a-zA-Z0-9_.-]+$');
                          if (!usernamePattern.hasMatch(value)) {
                            return "Username can only contain letters, numbers, underscores, periods, or dashes";
                          }
                          return null;
                        },
                        keyboardType: TextInputType.text,
                        maxLength: 20,
                        decoration: InputDecoration(
                          hintText: "@Username",
                          hintStyle: TextStyle(
                            color: Color(0xFF9B9B9B),
                            fontWeight: FontWeight.w400,
                            fontSize: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: BorderSide(color: Color(0xFFF790AD)),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Email
                      TextFormField(
                        autovalidateMode: AutovalidateMode.always,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Email can't be empty";
                          }
                          if (value.length > 254) {
                            return "Email can't exceed 254 characters";
                          }
                          if (!RegExp(r'^[a-zA-Z0-9._]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                        maxLength: 254,
                        decoration: InputDecoration(
                          hintText: "Email",
                          hintStyle: TextStyle(
                            color: Color(0xFF9B9B9B),
                            fontWeight: FontWeight.w400,
                            fontSize: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: BorderSide(color: Color(0xFFF790AD)),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        autovalidateMode: AutovalidateMode.always,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Password can't be empty";
                          }
                          if (value.length < 8) {
                            return "Password must be at least 8 characters long";
                          }
                          if (!RegExp(r'^(?=.*[A-Z])').hasMatch(value)) {
                            return "Password must contain at least one uppercase letter";
                          }
                          if (!RegExp(r'^(?=.*[a-z])').hasMatch(value)) {
                            return "Password must contain at least one lowercase letter";
                          }
                          if (!RegExp(r'^(?=.*\d)').hasMatch(value)) {
                            return "Password must contain at least one number";
                          }
                          if (!RegExp(r'^(?=.*[!@#\$%^&*])').hasMatch(value)) {
                            return "Password must contain at least one special character";
                          }
                          if (value.length > 16) {
                            return "Password can't exceed 16 characters";
                          }
                          return null;
                        },
                        maxLength: 16,
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: TextStyle(
                            color: Color(0xFF9B9B9B),
                            fontWeight: FontWeight.w400,
                            fontSize: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: BorderSide(color: Color(0xFFF790AD)),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Confirm password
                      TextFormField(
                        controller: _confirmPasswordController,
                        autovalidateMode: AutovalidateMode.always,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Confirm password can't be empty";
                          }
                          if (value != _passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Confirm Password",
                          hintStyle: TextStyle(
                            color: Color(0xFF9B9B9B),
                            fontWeight: FontWeight.w400,
                            fontSize: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: BorderSide(color: Color(0xFFF790AD)),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Sign up button
                      Container(
                        width: 410,
                        child: MaterialButton(
                          color: Color(0xFFF790AD),
                          textColor: Color(0xFFFFFFFF),
                          height: 50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileSetup(),
                                ),
                              );
                            }
                          },
                          child: Text("Sign up"),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Already have an account? Login
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                color: Color(0XFF695555),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: "Login",
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                color: Color(0xFFF790AD),
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HomePage(),
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




