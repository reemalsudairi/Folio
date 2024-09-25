// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: unused_import
import 'package:flutter_pw_validator/flutter_pw_validator.dart';
import 'package:folio/screens/ProfileSetup.dart';
import 'package:folio/screens/first.page.dart';
import 'package:folio/screens/homePage.dart';
import 'package:folio/screens/login.dart';
import 'package:image_picker/image_picker.dart';

class SignUp extends StatefulWidget {
 const SignUp({super.key});

 @override
 _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
 final GlobalKey<FormState> _formKey = GlobalKey();
 final TextEditingController _passwordController = TextEditingController();
 final TextEditingController _confirmPasswordController = TextEditingController();
 final TextEditingController _emailController = TextEditingController();
 final TextEditingController _usernameController = TextEditingController();
 

 bool isLoading = false;
 bool _obscurePassword = true; // Password visibility state
 bool _obscureConfirmPassword = true; // Confirm password visibility state

 final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
 final FirebaseFirestore _firestore = FirebaseFirestore.instance;// Firestore instance


 // Check if username or email already exists
 Future<bool> checkIfUsernameExists(String username) async {
   final QuerySnapshot result = await _firestore
       .collection('reader')
       .where('username', isEqualTo: username)
       .limit(1)
       .get();
   final List<DocumentSnapshot> documents = result.docs;
   return documents.isNotEmpty; // Returns true if username exists
 }

 Future<bool> checkIfEmailExists(String email) async {
   final QuerySnapshot result = await _firestore
       .collection('reader')
       .where('email', isEqualTo: email)
       .limit(1)
       .get();
   final List<DocumentSnapshot> documents = result.docs;
   return documents.isNotEmpty; // Returns true if email exists
 }

// Sign up function
String? _errorMessage;

Future<void> _signUp() async {
 if (_formKey.currentState!.validate()) {
   setState(() {
     isLoading = true;
     _errorMessage = null; // Reset error message
   });

   try {
     // Check if username already exists
     bool usernameExists = await checkIfUsernameExists(_usernameController.text.trim());
     if (usernameExists) {
       _errorMessage = 'Username is already in use';
       throw FirebaseAuthException(code: 'username-already-in-use');
     }

     // Check if email already exists
     bool emailExists = await checkIfEmailExists(_emailController.text.trim());
     if (emailExists) {
       _errorMessage = 'Email is already in use';
       throw FirebaseAuthException(code: 'email-already-in-use');
     }

     // Sign up the user using Firebase Auth
     UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
       email: _emailController.text.trim(),
       password: _passwordController.text.trim(),
     );

     // Add user data to Firestore "reader" collection
     await _firestore.collection('reader').doc(userCredential.user!.uid).set({
       'username': _usernameController.text.trim(),
       'email': _emailController.text.trim(),
       'uid': userCredential.user!.uid,
       'createdAt': Timestamp.now(),
     });

     // Navigate to the Profile Setup screen
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => ProfileSetup(userId: userCredential.user!.uid),
       ),
     );

   } on FirebaseAuthException catch (e) {
     // Handle Firebase Auth errors
     _errorMessage = _handleAuthError(e);
   } catch (e) {
     // Handle any other errors
     _errorMessage = "An unexpected error occurred.";
   } finally {
     setState(() {
       isLoading = false; // Ensure loading state is reset
     });
   }
 } else {
   _errorMessage = "Please fill in all fields correctly.";
   setState(() {
     isLoading = false; // Reset loading state if validation fails
   }); // Update UI to show the error message
 }
}

String _handleAuthError(FirebaseAuthException error) {
 switch (error.code) {
   case 'username-already-in-use':
     return 'Username is already in use.';
   case 'email-already-in-use':
     return 'Email is already in use.';
   case 'weak-password':
     return 'Password is too weak.';
   case 'invalid-email':
     return 'Invalid email address.';
   default:
     return 'An error occurred. Please try again.';
 }
}

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     backgroundColor: const Color(0xFFF8F8F3),
     body: Center(
       child: SingleChildScrollView( 
       child: ConstrainedBox(
        constraints:
         BoxConstraints(minHeight: MediaQuery.of(context).size.height),
         child: IntrinsicHeight(

         child: Column(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           crossAxisAlignment: CrossAxisAlignment.center,
           children: [
            const SizedBox(height: 30),
               Stack(
                 children:[  Align(
                       alignment: Alignment.center,
                       child: Image.asset(
                       "assets/images/Logo.png",
                         width: 500,
                         height: 300,
                         fit: BoxFit
                         .cover, // Ensures the image fits within the container
                       ),
                     ),
                // Back arrow button positioned at the top left
                 Align(
                   alignment: Alignment.topLeft,
                   child: IconButton(
                     icon: const Icon(Icons.arrow_back),
                     onPressed: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => WelcomePage(),
                         ),
                       );
                     },
                   ),
                 ),
                 const SizedBox(height: 10),
              // Introductory text at the bottom of the image
                 const Positioned(
                   bottom: 10, // Position the text 10 pixels from the bottom
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
             
   
             // Form fields
             Container(
               width: 410,
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(40),
               ),
               child: Form(
                 key: _formKey,
                  child: Column(
                  children: [
                 const SizedBox(height: 20),
                  //error msg 
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
   //username                 
 TextFormField(
 controller: _usernameController,
 autovalidateMode: AutovalidateMode.onUserInteraction,
 inputFormatters: [
  FilteringTextInputFormatter.deny(RegExp(r'\s')), ],
 validator: (value) {
   if (value == null || value.isEmpty) {
     return "Username is required"; // This will trigger the error border when empty
   }
   if (value.length < 3) {
     return "Username can't be less than 3 characters";
   }
   RegExp usernamePattern = RegExp(r'^[a-zA-Z0-9_.-]+$');
   if (!usernamePattern.hasMatch(value)) {
     return "Characters like @, #, and spaces aren't allowed";
   }
   return null; // No error, so no red border
 },
 keyboardType: TextInputType.text,
 maxLength: 20,
 decoration: InputDecoration(
 hintText: "@Username",
 hintStyle: const TextStyle(
 color: Color(0xFF695555),
 fontWeight: FontWeight.w400,
 fontSize: 20,
   ),
   filled: true,
   fillColor: Colors.white,
   border: OutlineInputBorder(
     borderRadius: BorderRadius.circular(40),
     borderSide: const BorderSide(color: Color(0xFFF790AD)), // Pink border initially
   ),
   enabledBorder: OutlineInputBorder(
     borderRadius: BorderRadius.circular(40),
     borderSide: const BorderSide(color: Color(0xFFF790AD)), // Pink border when enabled
   ),
   focusedBorder: OutlineInputBorder(
     borderRadius: BorderRadius.circular(40),
     borderSide: const BorderSide(color: Color(0xFFF790AD)), // Pink border when focused
   ),
  suffixIcon: Padding(
     padding: const EdgeInsets.only(right: 45.0,top: 10.0), // Right padding
     child: RichText(
       text: TextSpan(
         text: '*',
         style: TextStyle(color: Colors.red, fontSize: 20),
       ),
     ),
 ),
  
  
),
 ),
                     
const SizedBox(height: 20),

 // Email
 TextFormField(
 controller: _emailController,
 autovalidateMode: AutovalidateMode.onUserInteraction,
 keyboardType: TextInputType.emailAddress,
 inputFormatters: [
 FilteringTextInputFormatter.deny(RegExp(r'\s')),],
 validator: (value) {
   if (value == null || value.isEmpty) {
     return "Email is required"; // This will trigger the error border when empty
   }
   if (value.length > 254) {
     return "Email can't exceed 254 characters";
   }
   if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value) &&
       !RegExp(r'^[0-9]+@student\.[a-zA-Z]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
     return "Enter a valid email address";
   }
   return null; // No error, so no red border
 },
 maxLength: 254,
 decoration: InputDecoration(
 hintText: "Email",
 hintStyle: const TextStyle(
 color: Color(0xFF695555),
 fontWeight: FontWeight.w400,
 fontSize: 20,
   ),
   filled: true,
   fillColor: Colors.white,
   border: OutlineInputBorder(
     borderRadius: BorderRadius.circular(40),
     borderSide: const BorderSide(color: Color(0xFFF790AD)), // Pink border initially
   ),
   enabledBorder: OutlineInputBorder(
     borderRadius: BorderRadius.circular(40),
     borderSide: const BorderSide(color: Color(0xFFF790AD)), // Pink border when enabled
   ),
   focusedBorder: OutlineInputBorder(
     borderRadius: BorderRadius.circular(40),
     borderSide: const BorderSide(color: Color(0xFFF790AD)), // Pink border when focused
   ),
   suffixIcon: Padding(
     padding: const EdgeInsets.only(right: 45.0,top: 10.0), // Right padding
     child: RichText(
       text: TextSpan(
         text: '*',
         style: TextStyle(color: Colors.red, fontSize: 20),
       ),
     ),
 ),
 ),
),

const SizedBox(height: 20),

 // Password
 TextFormField(
 controller: _passwordController,
 autovalidateMode: AutovalidateMode.onUserInteraction,
 keyboardType: TextInputType.text,
 obscureText: _obscurePassword,
 inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s')), ],
 validator: (value) {
   if (value!.isEmpty) {
     return "Password is required ";
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
   if (value.contains(' ')) {
     return "Password cannot contain spaces";
   }
   return null;
 },
maxLength: 16,
decoration: InputDecoration(
hintText: "Password",
hintStyle: const TextStyle(
color: Color(0xFF695555),
fontWeight: FontWeight.w400,
fontSize: 20, 
 ),
                        
 filled: true, // Make sure the field is filled with the color
 fillColor: Colors.white, // Set the background color of the field
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
 suffixIcon: Padding(
 padding: const EdgeInsets.only(right: 8.0), // Right padding for the icon
 child: Row(
   mainAxisSize: MainAxisSize.min, // Ensure the row takes minimal space
   children: [
     // Asterisk on the left side of the icon
     RichText(
       text: TextSpan(
         text: '*',
         style: TextStyle(color: Colors.red, fontSize: 20),
       ),
     ),
     // Icon button for visibility toggle
     IconButton(
       icon: Icon(
         _obscurePassword ? Icons.visibility_off : Icons.visibility,
         color: const Color(0xFFF790AD),
       ),
       onPressed: () {
         setState(() {
           _obscurePassword = !_obscurePassword;
         });
       },
     ),
   ],
 ),
),

   ),//input decoration
  ),


//مدري هذا وش فايدته 
new FlutterPwValidator(
   controller: _passwordController,
   minLength: 8,
   uppercaseCharCount: 1,
   lowercaseCharCount: 1,
   numericCharCount: 1,
   specialCharCount: 1,
   width: 400,
   height: 165,
   onSuccess: _nothingg
),

 const SizedBox(height: 20),


 // Confirm password
 TextFormField(
 controller: _confirmPasswordController,
 autovalidateMode: AutovalidateMode.onUserInteraction,
 keyboardType: TextInputType.text,
 maxLength: 16,
 obscureText: _obscureConfirmPassword,
 validator: (value) {
 if (value!.isEmpty) {
return "Confirm Password is required ";}

 if (value != _passwordController.text) {
return "Passwords do not match";}

return null;},
decoration: InputDecoration(
hintText: "Confirm Password",
hintStyle: const TextStyle(
color: Color(0xFF695555),
fontWeight: FontWeight.w400,
 fontSize: 20,
 ),
 filled: true, // Make sure the field is filled with the color
 fillColor: Colors.white, // Set the background color of the field
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
    suffixIcon: Padding(
 padding: const EdgeInsets.only(right: 8.0), // Right padding for the icon
 child: Row(
   mainAxisSize: MainAxisSize.min, // Ensure the row takes minimal space
   children: [
     // Asterisk on the left side of the icon
     RichText(
       text: TextSpan(
         text: '*',
         style: TextStyle(color: Colors.red, fontSize: 20),
       ),
     ),
     // Icon button for visibility toggle
     IconButton(
       icon: Icon(
         _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
         color: const Color(0xFFF790AD),
       ),
       onPressed: () {
         setState(() {
           _obscureConfirmPassword = !_obscureConfirmPassword;
         });
       },
     ),
   ],
 ),
),
   ),
  ),

  const SizedBox(height: 20),

                    // Sign up button
                     Padding(padding:const EdgeInsets.symmetric(vertical: 20),
                     child: Column(
                       children: [
                          isLoading
                     ? const CircularProgressIndicator()
                     : SizedBox(
                         width: 410,
                         child: MaterialButton(
                           color: const Color(0xFFF790AD),
                           textColor: const Color(0xFFFFFFFF),
                           height: 50,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(40),
                           ),
                           onPressed: _signUp,
                           child: const Text(
                             "Sign up",
                             style: TextStyle(
                               fontFamily: 'Roboto',
                               fontWeight: FontWeight.w700,
                               fontSize: 20,
                               color: Colors.white,
                             ),
                           ),
                         ),
                       ),
                   Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: const Text(
                        'Log in',
                        style: TextStyle(color: Color(0xFFF790AD)),
                      ),
                    ),
                  ],
                ),
                                 const SizedBox(height: 20),
               ],
             ),
           ),
         ],
       ),
     ),
   ),
           ]
         
 ),
       ),
       ),
   
     ),
   
   ),
   );
 }
//مدري وش فايدته 
 _nothingg() {
 }
}
