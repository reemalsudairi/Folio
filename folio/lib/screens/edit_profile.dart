import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class EditProfile extends StatefulWidget {
  final String userId;
  final String name;
  final String bio;
  final String profilePhotoUrl;
  final int booksGoal;

  const EditProfile({
    super.key,
    required this.userId,
    required this.name,
    required this.bio,
    required this.profilePhotoUrl,
    required this.booksGoal,
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _booksController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

 
  // Firestore instance
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _bioController.text = widget.bio;
    _booksController.text = widget.booksGoal.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _booksController.dispose();
    super.dispose();
  }

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

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final userId = widget.userId;

        // Prepare the profile data
        final userProfile = {
          'name': _nameController.text,
          'bio': _bioController.text,
          'books': int.parse(_booksController.text),
          'profilePhoto': _imageFile != null
              ? await _uploadProfilePhoto(userId)
              : widget.profilePhotoUrl,
        };

        // Update the Firestore document
        await _firestore
            .collection('reader')
            .doc(userId)
            .set(userProfile, SetOptions(merge: true));

        // Return the updated data to the previous screen
        Navigator.pop(context, userProfile); // Pass updated profile data
      } catch (e) {
        print('Error saving profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }

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
            ProfilePhotoWidget(
              initialImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : _imageFile == null && widget.profilePhotoUrl.isNotEmpty
                      ? NetworkImage(widget.profilePhotoUrl)
                      : const AssetImage('assets/images/profile_pics.png'),
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
                    const SizedBox(height: 20),
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
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: const BorderSide(color: Color(0xFFF790AD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFFF790AD)),
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _booksController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: "How many books do you want to read this year?",
                        hintStyle: const TextStyle(
                          color: Color(0xFF9B9B9B),
                          fontWeight: FontWeight.w400,
                          fontSize: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: const BorderSide(color: Color(0xFFF790AD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: const BorderSide(color: Color(0xFFF790AD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFFF790AD)),
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 410,
                      child: MaterialButton(
                        color: const Color(0xFFF790AD),
                        textColor: const Color(0xFFFFFFFF),
                        height: 50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        onPressed: _saveProfile,
                        child: const Text(
                          "Save",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFFF8F8F3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF000000),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            color: const Color(0xFF000000),
            onPressed: _saveProfile,
          ),
        ],
      ),
    );
  }
}

class ProfilePhotoWidget extends StatelessWidget {
  final ImageProvider<Object>? initialImage;
  final void Function(File) onImagePicked;

  const ProfilePhotoWidget({
    super.key,
    this.initialImage,
    required this.onImagePicked,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 70,
            backgroundImage: initialImage ?? const AssetImage('assets/images/profile_pics.png'),
            backgroundColor: Colors.grey.shade200,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Color(0xFFF790AD)),
              onPressed: () async {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  onImagePicked(File(pickedFile.path));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
