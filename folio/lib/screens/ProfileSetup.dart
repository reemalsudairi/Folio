
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/homePage.dart';
import 'package:image_picker/image_picker.dart';

// Convert MyApp to ProfileSetup
class ProfileSetup extends StatefulWidget {
    final String userId;
  const ProfileSetup({super.key, required this.userId});

  @override
  _ProfileSetupState createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetup> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _booksController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Add your Firebase Auth instance
  final _auth = FirebaseAuth.instance;

  // Firestore instance
  final _firestore = FirebaseFirestore.instance;

    // Function to pick image from gallery or camera
  Future<void> _showImagePickerOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => BottomSheet(
        onClosing: () {},
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Take a Photo'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop(); // Close the bottom sheet
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop(); // Close the bottom sheet
              },
            ),
          ],
        ),
      ),
    );
  }

  // Function to pick an image
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Function to save profile data to Firestore
void _saveProfile() async {
  // Ensure the form is valid
  if (_formKey.currentState?.validate() ?? false) {
    try {
      // Get the current user from FirebaseAuth
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        final userId = user.uid;  // Get the user ID

        // Prepare the profile data
        final userProfile = {
          'name': _nameController.text,
          'bio': _bioController.text,
          'books': _booksController.text,
          'profilePhoto': _imageFile != null
              ? await _uploadProfilePhoto(userId)  // Upload the profile photo and get the URL
              : null,
        };

        // Update the Firestore document with the profile data
        await FirebaseFirestore.instance
            .collection('reader')
            .doc(userId)
            .set(userProfile, SetOptions(merge: true));  // Merge to avoid overwriting existing data

        // Navigate to HomePage after saving the profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      // Handle error, show a snackbar or dialog if needed
    }
  }
}


  // Function to upload profile photo to Firebase Storage
  Future<String?> _uploadProfilePhoto(String userId) async {
    if (_imageFile != null) {
      final ref = FirebaseStorage.instance.ref().child('profile_photos').child('$userId.jpg');
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 36),

              // Back icon
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  iconSize: 50,
                  icon: const Icon(Icons.arrow_back_ios),
                ),
              ),

                // Profile photo with pencil icon
              ProfilePhotoWidget(
                onImagePicked: (File imageFile) {
                  setState(() {
                    _imageFile = imageFile;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Form fields
              Container(
                width: 410,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 40),

                          // Name
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            maxLength: 50, // Set maximum length of name field
                            decoration: InputDecoration(
                              hintText: "Name",
                              hintStyle: const TextStyle(
                                color: Color(0xFF9B9B9B),
                                fontWeight: FontWeight.w400,
                                fontSize: 20,
                              ),
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
                                borderSide:
                                    const BorderSide(color: Color(0xFFF790AD)),
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Bio
                          TextFormField(
                            controller: _bioController,
                            keyboardType: TextInputType.text,
                            maxLines: 4,
                            maxLength: 152,
                            decoration: InputDecoration(
                              hintText: "Bio",
                              hintStyle: const TextStyle(
                                color: Color(0xFF9B9B9B),
                                fontWeight: FontWeight.w400,
                                fontSize: 20,
                              ),
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
                                borderSide:
                                    const BorderSide(color: Color(0xFFF790AD)),
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Books number
                          TextFormField(
                            controller: _booksController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText:
                                  "How many books do you want to read in this year?",
                              hintStyle: const TextStyle(
                                color: Color(0xFF9B9B9B),
                                fontWeight: FontWeight.w400,
                                fontSize: 15,
                              ),
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
                                borderSide:
                                    const BorderSide(color: Color(0xFFF790AD)),
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Save button
                          SizedBox(
                            width: 410, // Match the width of the TextField
                            child: MaterialButton(
                              color: const Color(0xFFF790AD),
                              textColor: const Color(0xFFFFFFFF),
                              height: 50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                             onPressed: _saveProfile,
                              child: Text("Save",
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),


                          const SizedBox(height: 20),

                          // Skip profile setup for now?
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: "Skip profile setup for now? ",
                                  style: TextStyle(
                                      fontFamily: 'Roboto',
                                      color: Color(0XFF695555),
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: "Skip",
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Color(0xFFF790AD),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // Navigate to home page
                                    Navigator.pushReplacement(
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
                          const SizedBox(
                              height: 20), // Additional space after the text
                        ],
                      ),
                    ),
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

class ProfilePhotoWidget extends StatefulWidget {
  final Function(File) onImagePicked; // Callback function to notify the parent widget
  const ProfilePhotoWidget({super.key, required this.onImagePicked});

  @override
  _ProfilePhotoWidgetState createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Function to pick image from gallery or camera
  Future<void> _showImagePickerOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => BottomSheet(
        onClosing: () {},
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Take a Photo'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop(); // Close the bottom sheet
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop(); // Close the bottom sheet
              },
            ),
          ],
        ),
      ),
    );
  }

  // Function to pick an image
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      widget.onImagePicked(_imageFile!); // Notify the parent widget
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Profile photo (CircleAvatar)
        CircleAvatar(
          radius: 64,
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!)
              : const NetworkImage(
                      "https://i.pinimg.com/564x/c5/07/8e/c5078ec7b5679976947d90e4a19e1bbb.jpg")
                  as ImageProvider,
        ),

        // Pencil icon for editing
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              _showImagePickerOptions(context); // Show the option to pick image
            },
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: const Color(0xFFF790AD),
              ),
              child: const Icon(Icons.edit, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
