// ignore_for_file: prefer_const_constructors

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:signup_one/homePage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  GlobalKey<FormState> formstate=GlobalKey();
  String username="";
  String email="";
  String password="";
  String confirmpassword="";
  


  // Define controllers for password and confirm password
final TextEditingController passwordController = TextEditingController();
final TextEditingController confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                      print("on pressed");
                    },
                    iconSize: 50,
                    icon: Icon(Icons.arrow_back_ios),
                  ),
                ),

                Stack(
  alignment: Alignment.center,  // Centers the stack content
  children: [
    // Logo (Image)
    Image.asset(
      "images/Logo.png",
      width: 500,
      height: 300,
      fit: BoxFit.cover,  // Ensures the image fits within the container
    ),
    
    // Introductory text at the bottom of the image
    Positioned(
      bottom: 10,  // Position the text 10 pixels from the bottom of the image
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



                // ignore: prefer_const_constructors
                SizedBox(height: 20),

                // Form fields
Container(
  width: 410,
  padding: EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: Color(0xFFFFFFFF),
    borderRadius: BorderRadius.circular(40),
  ),
  child: SingleChildScrollView( // Add SingleChildScrollView here
    child: ConstrainedBox( // Wrap the content in ConstrainedBox
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6, // Adjust the height to be scrollable based on screen size
      ),
      child:Form(
        key: formstate,
      child: Column(
        children: [
          SizedBox(height: 20),


          // Username
          TextFormField(
          
            autovalidateMode: AutovalidateMode.always,
            validator: (value) {


              //checking that the username isn't empty
              if(value!.isEmpty){
                return "the username field is empty";
                
              }
              
              //checking that the user name is not too short
              if(value.length < 3){
                  return "the username can't be less than 3 characters";
                }
                // Regular expression to match valid username characters
               RegExp usernamePattern = RegExp(r'^[a-zA-Z0-9_.-]+$');

               // Check if the username contains only valid characters
               if (!usernamePattern.hasMatch(value)) {
               return "Username can only contain letters, numbers, underscores, periods, or dashes";
                 }

                 //checking that the username isn't taken
                 //------------------------------------------------------------------





                 //------------------------------------------------------------------

                 return null; // Return null if all validations pass

            },
            keyboardType: TextInputType.text,
            maxLength: 20,
            enabled: true,
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Color(0xFFF790AD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF790AD)),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),

          SizedBox(height: 20),

          // Email
          TextFormField(
            
            autovalidateMode: AutovalidateMode.always,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
            // Check if the email is empty
           if (value!.isEmpty) {
          return "Email can't be empty";  }

           // Check if the email exceeds the max length (e.g., 254)
           if (value.length > 254) {
            return "Email can't exceed 254 characters";
            }

          // Check for valid email format using regex
           if (!RegExp(r'^[a-zA-Z0-9._]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
           return "Enter a valid email address";
          }
          //checking that the email isn't already exists
                 //------------------------------------------------------------------





                 //------------------------------------------------------------------


           return null; // Return null if all validations pass
           },
            maxLength: 254,
            
            enabled: true,
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Color(0xFFF790AD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF790AD)),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),

          SizedBox(height: 20),

          // Password
          TextFormField(
             controller: passwordController,
            autovalidateMode: AutovalidateMode.always,
            keyboardType: TextInputType.text,
            obscureText: true,
            validator: (value) {
            // Check if the password is empty
           if (value!.isEmpty) {
            return "Password can't be empty";
            }

           // Check if the password length is at least 8 characters
            if (value.length < 8) {
           return "Password must be at least 8 characters long";
          }

           // Check for at least one uppercase letter
          if (!RegExp(r'^(?=.*[A-Z])').hasMatch(value)) {
           return "Password must contain at least one uppercase letter";
          }

          // Check for at least one lowercase letter
        if (!RegExp(r'^(?=.*[a-z])').hasMatch(value)) {
          return "Password must contain at least one lowercase letter";
         }

         // Check for at least one number
         if (!RegExp(r'^(?=.*\d)').hasMatch(value)) {
          return "Password must contain at least one number";
         }

        // Check for at least one special character
         if (!RegExp(r'^(?=.*[!@#\$%^&*])').hasMatch(value)) {
        return "Password must contain at least one special character ";
        }
        if (value.length > 16) {
            return "Password can't exceed 16 characters";
            }

         return null; // Return null if all validations pass
         },
           maxLength: 16, // Maximum length of the password
            enabled: true,
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Color(0xFFF790AD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF790AD)),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),

          SizedBox(height: 20),

          // Confirm password
          TextFormField(
            controller: confirmPasswordController,
            autovalidateMode: AutovalidateMode.always,
            keyboardType: TextInputType.text,
            obscureText: true,
            validator: (value) {
           // Check if the confirm password field is empty
           if (value!.isEmpty) {
            return "Confirm password can't be empty";
           }

           // Check if the confirm password matches the password field
           if (value != passwordController.text) {

           return "Passwords do not match";
            }

           return null; // Return null if all validations pass
             },
             
            enabled: true,
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Color(0xFFF790AD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF790AD)),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),

          SizedBox(height: 20),

          // Sign up button (same width as TextField)
          Container(
            width: 410,  // Match the width of the TextField
            child: MaterialButton(
              color: Color(0xFFF790AD),
              textColor: Color(0xFFFFFFFF),
              height: 50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              onPressed: () {
                if(formstate.currentState!.validate()){

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
                  style: TextStyle(fontFamily: 'Roboto',color: Color(0XFF695555),fontWeight: FontWeight.bold,
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
                      // Navigate to login page
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
          SizedBox(height: 20), // Additional space after the text
        ],
      ),),
    ),
  ),
),
],
          ),
        ),
      ),
    ),);
  }
  
  
}



