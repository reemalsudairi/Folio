import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/homePage.dart';
import 'package:image_picker/image_picker.dart';

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

  // Firebase Auth instance
  final _auth = FirebaseAuth.instance;
  // Firestore instance
  final _firestore = FirebaseFirestore.instance;

  // Dispose controllers to prevent memory leaks
  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _booksController.dispose();
    super.dispose();
  }

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
          ],
        ),
      ),
    );
  }

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
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userId = user.uid;

          // Prepare profile data
          final userProfile = {
            'name': _nameController.text,
            'bio': _bioController.text,
            'books': _booksController.text,
            'profilePhoto': _imageFile != null
                ? await _uploadProfilePhoto(userId)
                : null,
          };

          await FirebaseFirestore.instance
              .collection('reader')
              .doc(userId)
              .set(userProfile, SetOptions(merge: true));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (e) {
        print('Error saving profile: $e');
        // Show error message (optional)
      }
    }
  }

  // Upload profile photo to Firebase Storage
  Future<String?> _uploadProfilePhoto(String userId) async {
    if (_imageFile != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('$userId.jpg');
        await ref.putFile(_imageFile!);
        return await ref.getDownloadURL();
      } catch (e) {
        print('Error uploading profile photo: $e');
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            // Profile photo with pencil icon
            ProfilePhotoWidget(
              onImagePicked: (File imageFile) {
                setState(() {
                  _imageFile = imageFile;
                });
              },
            ),
            const SizedBox(height: 20),
            Container(
              width: 410,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(40),
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
                      maxLength: 50,
                      decoration: InputDecoration(
                        hintText: "Name",
                        hintStyle: const TextStyle(
                          color: Color(0xFF9B9B9B),
                          fontSize: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: const BorderSide(color: Color(0xFFF790AD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: const BorderSide(color: Color(0xFFF790AD)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
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
                          fontSize: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: const BorderSide(color: Color(0xFFF790AD)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Books number
                    TextFormField(
                      controller: _booksController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "How many books do you want to read in this year?",
                        hintStyle: const TextStyle(
                          color: Color(0xFF9B9B9B),
                          fontSize: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: const BorderSide(color: Color(0xFFF790AD)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the number of books';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Save button
                    SizedBox(
                      width: 410,
                      child: MaterialButton(
                        color: const Color(0xFFF790AD),
                        textColor: Colors.white,
                        height: 50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        onPressed: _saveProfile,
                        child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Skip profile setup
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: "Skip profile setup for now? ",
                            style: TextStyle(
                                color: Color(0XFF695555), fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: "Skip",
                            style: const TextStyle(
                              color: Color(0xFFF790AD),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HomePage()),
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
          ],
        ),
      ),
    );
  }
}

class ProfilePhotoWidget extends StatefulWidget {
  final Function(File) onImagePicked;
  const ProfilePhotoWidget({super.key, required this.onImagePicked});

  @override
  _ProfilePhotoWidgetState createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

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
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        widget.onImagePicked(_imageFile!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 70,
          backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
          child: _imageFile == null
              ? const Icon(Icons.person, size: 70)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => _showImagePickerOptions(context),
          ),
        ),
      ],
    );
  }
}
