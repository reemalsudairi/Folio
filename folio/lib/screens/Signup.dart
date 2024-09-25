// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flutter_pw_validator/flutter_pw_validator.dart';
import 'package:folio/screens/ProfileSetup.dart';
import 'package:folio/screens/first.page.dart';
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
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  // final TextEditingController _nameController = TextEditingController();
  // final TextEditingController _bioController = TextEditingController();
  // final TextEditingController _booksController = TextEditingController();
  // File? _imageFile;
  // final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  bool _obscurePassword = true; // Password visibility state
  bool _obscureConfirmPassword = true; // Confirm password visibility state

  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance

// @override
//   void dispose() {
//     _nameController.dispose();
//     _bioController.dispose();
//     _booksController.dispose();
//     super.dispose();
//   }

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
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // Check if username already exists
        bool usernameExists =
            await checkIfUsernameExists(_usernameController.text.trim());
        if (usernameExists) {
          throw FirebaseAuthException(code: 'username-already-in-use');
        }

        // Check if email already exists
        bool emailExists =
            await checkIfEmailExists(_emailController.text.trim());
        if (emailExists) {
          throw FirebaseAuthException(code: 'email-already-in-use');
        }

        // Sign up the user using Firebase Auth
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Add user data to Firestore "reader" collection
        await _firestore
            .collection('reader')
            .doc(userCredential.user!.uid)
            .set({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'uid': userCredential.user!.uid,
          //    'name': _nameController.text.trim(),
          //  'bio': _bioController.text.trim(),
          // 'books': _booksController.text.trim(),
          'createdAt': Timestamp.now(),
        });

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProfileSetup(userId: userCredential.user!.uid)),
        );
      } on FirebaseAuthException catch (e) {
        // Handle Firebase Auth errors
        String message = 'An error occurred';
        if (e.code == 'username-already-in-use') {
          message = 'Username is already in use';
        } else if (e.code == 'email-already-in-use') {
          message = 'Email is already in use';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email address';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        // Handle any other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Align(
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
                        iconSize: 40,
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
                  ],
                ),
                const SizedBox(height: 10),
//              ProfilePhotoWidget(
//   onImagePicked: (File? imageFile) {
//     setState(() {
//       _imageFile = imageFile; // Handle null when deleting the photo
//     });
//   },
// ),
                const SizedBox(height: 20),
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
                        const SizedBox(height: 40),
                        // Name
                        //                         TextFormField(
                        //                           controller: _nameController,
                        //                           keyboardType: TextInputType.name,
                        //                           autovalidateMode: AutovalidateMode.always,
                        //                       validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return "*"; // Name is required
                        //   }
                        //   if (value.trim().isEmpty) {
                        //     return "Name cannot contain only spaces";
                        //   }
                        //   if (value.startsWith(' ')) {
                        //     return "Name cannot start with spaces";
                        //   }
                        //   return null; // Input is valid
                        // },
                        //                           maxLength: 50, // Set maximum length of name field
                        //                           decoration: InputDecoration(
                        //                             hintText: "Name",

                        //                             hintStyle: const TextStyle(
                        //                               color: Color(0xFF695555),
                        //                               fontWeight: FontWeight.w400,
                        //                               fontSize: 20,
                        //                             ),
                        //                              filled: true, // Make sure the field is filled with the color
                        //                              fillColor: Colors.white,
                        //                             border: OutlineInputBorder(
                        //                               borderRadius: BorderRadius.circular(40),
                        //                               borderSide:
                        //                                   const BorderSide(color: Color(0xFFF790AD)),
                        //                             ),
                        //                             focusedBorder: OutlineInputBorder(
                        //                               borderRadius: BorderRadius.circular(40),
                        //                               borderSide:
                        //                                   const BorderSide(color: Color(0xFFF790AD)),
                        //                             ),
                        //                             enabledBorder: OutlineInputBorder(
                        //                               borderSide:
                        //                                   const BorderSide(color: Color(0xFFF790AD)),
                        //                               borderRadius: BorderRadius.circular(40),
                        //                             ),
                        //                             errorBorder: OutlineInputBorder(
                        //                             borderRadius: BorderRadius.circular(40),
                        //                             borderSide: const BorderSide(color: Color(0xFFF790AD)),
                        //                             ),
                        //                             focusedErrorBorder: OutlineInputBorder(
                        //     borderRadius: BorderRadius.circular(40),
                        //     borderSide: const BorderSide(color: Color(0xFFF790AD)),
                        //   ),
                        //                           ),
                        //                         ),

                        const SizedBox(height: 20),

                        // Username
                        TextFormField(
                          controller: _usernameController,
                          autovalidateMode: AutovalidateMode.always,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "* ";
                            }
                            if (value.length < 3) {
                              return "Username can't be less than 3 characters";
                            }
                            RegExp usernamePattern =
                                RegExp(r'^[a-zA-Z0-9_.-]+$');
                            if (!usernamePattern.hasMatch(value)) {
                              return "characters like @, #, and spaces aren't allowed";
                            }
                            return null;
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
                            filled:
                                true, // Make sure the field is filled with the color
                            fillColor: Colors
                                .white, // Set the background color of the field
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          autovalidateMode: AutovalidateMode.always,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "* ";
                            }
                            if (value.length > 254) {
                              return "Email can't exceed 254 characters";
                            }
                            // Regular expression to match both regular email and university email format
                            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                    .hasMatch(value) &&
                                !RegExp(r'^[0-9]+@student\.[a-zA-Z]+\.[a-zA-Z]{2,}$')
                                    .hasMatch(value)) {
                              return "Enter a valid email address";
                            }

                            return null;
                          },
                          maxLength: 254,
                          decoration: InputDecoration(
                            hintText: "Email",
                            hintStyle: const TextStyle(
                              color: Color(0xFF695555),
                              fontWeight: FontWeight.w400,
                              fontSize: 20,
                            ),
                            filled:
                                true, // Make sure the field is filled with the color
                            fillColor: Colors
                                .white, // Set the background color of the field
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          autovalidateMode: AutovalidateMode.always,
                          keyboardType: TextInputType.text,
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "* ";
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
                            if (!RegExp(r'^(?=.*[!@#\$%^&*])')
                                .hasMatch(value)) {
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

                            filled:
                                true, // Make sure the field is filled with the color
                            fillColor: Colors
                                .white, // Set the background color of the field
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            suffixIcon: IconButton(
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
                                }),
                          ),
                        ),

                        FlutterPwValidator(
                            controller: _passwordController,
                            minLength: 8,
                            uppercaseCharCount: 1,
                            lowercaseCharCount: 1,
                            numericCharCount: 1,
                            specialCharCount: 1,
                            width: 400,
                            height: 165,
                            onSuccess: _nothingg),

                        const SizedBox(height: 20),

                        // Confirm password
                        TextFormField(
                          controller: _confirmPasswordController,
                          autovalidateMode: AutovalidateMode.always,
                          keyboardType: TextInputType.text,
                          maxLength: 16,
                          obscureText: _obscureConfirmPassword,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "* ";
                            }
                            if (value != _passwordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Confirm Password",
                            hintStyle: const TextStyle(
                              color: Color(0xFF695555),
                              fontWeight: FontWeight.w400,
                              fontSize: 20,
                            ),
                            filled:
                                true, // Make sure the field is filled with the color
                            fillColor: Colors
                                .white, // Set the background color of the field
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF790AD)),
                            ),
                            suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFFF790AD),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                }),
                          ),
                        ),

                        const SizedBox(height: 20),

//                       // Bio
//                     TextFormField(
//                       controller: _bioController,
//                       keyboardType: TextInputType.text,
//                       maxLines: 4,
//                       maxLength: 152,
//                       decoration: InputDecoration(
//                         hintText: "Bio",
//                         hintStyle: const TextStyle(
//                           color: Color(0xFF695555),
//                           fontSize: 20,
//                         ), filled: true, // Make sure the field is filled with the color
//                                fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(40),
//                           borderSide: const BorderSide(color: Color(0xFFF790AD)),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(40),
//                           borderSide: const BorderSide(color: Color(0xFFF790AD)),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderSide: const BorderSide(color: Color(0xFFF790AD)),
//                           borderRadius: BorderRadius.circular(40),
//                         ),
//                       ),
//                     ),

//                      const SizedBox(height: 20),

// // Books number input field
// TextFormField(
//   controller: _booksController,
//   keyboardType: TextInputType.number,
//    inputFormatters: [FilteringTextInputFormatter.digitsOnly], // This ensures only numbers are allowed
//   decoration: InputDecoration(
//     hintText: "How many books do you want to read in this year?",
//     hintStyle: const TextStyle(
//       color: Color(0xFF695555),
//       fontWeight: FontWeight.w400,
//       fontSize: 15,
//     ), filled: true, // Make sure the field is filled with the color
//                                fillColor: Colors.white,
//     border: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(40),
//       borderSide: const BorderSide(color: Color(0xFFF790AD)),
//     ),
//     focusedBorder: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(40),
//       borderSide: const BorderSide(color: Color(0xFFF790AD)),
//     ),
//     enabledBorder: OutlineInputBorder(
//       borderSide: const BorderSide(color: Color(0xFFF790AD)),
//       borderRadius: BorderRadius.circular(40),
//     ),
//   ),
// ),

                        const SizedBox(height: 20),

                        // Sign up button
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
                                  child: const Text("Sign up"),
                                ),
                              ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Already have an account? Login
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Color(0XFF695555),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: "Login",
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Color(0xFFF790AD),
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _nothingg() {}
}

class ProfilePhotoWidget extends StatefulWidget {
  final Function(File?) onImagePicked;

  const ProfilePhotoWidget({super.key, required this.onImagePicked});

  @override
  _ProfilePhotoWidgetState createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  late ImageProvider<Object> _currentImage;

  @override
  void initState() {
    super.initState();
    _currentImage = const AssetImage('assets/images/profile_pic.png');
  }

  // Function to show options for picking an image
  Future<void> _showImagePickerOptions(BuildContext context) async {
    // Check if the current image is the default image
    bool isDefaultImage = _imageFile == null;

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 50.0),
        child: BottomSheet(
          onClosing: () {},
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              if (!isDefaultImage)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete Photo'),
                  onTap: () {
                    _deletePhoto();
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to pick an image from the camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _currentImage = FileImage(_imageFile!);
      });
      widget.onImagePicked(
          _imageFile); // Notify parent widget with the picked image
    }
  }

  // Function to delete the selected photo and revert to the default image
  void _deletePhoto() {
    setState(() {
      _imageFile = null;
      _currentImage = const AssetImage('assets/images/profile_pic.png');
    });
    widget
        .onImagePicked(null); // Notify parent widget that the photo is deleted
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Display profile photo with a border
        CircleAvatar(
          radius: 64,
          backgroundImage: _currentImage,
          backgroundColor: const Color(0xFFF790AD),
        ),
        // Button to edit or change the photo
        Positioned(
          bottom: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.camera_alt,
                color: Color.fromARGB(255, 53, 31, 31)),
            onPressed: () => _showImagePickerOptions(context),
          ),
        ),
      ],
    );
  }
}
