import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CustomTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    int? value = int.tryParse(newValue.text);
    if (value == null || value < 0 || value > 1000) {
      return oldValue;
    }

    return newValue;
  }
}

// Custom InputFormatter for restricting the number range
class NumberRangeFormatter extends TextInputFormatter {
  final int min;
  final int max;

  NumberRangeFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    int? value = int.tryParse(newValue.text);
    if (value == null || value < min || value > max) {
      return oldValue; // Keep the old value if it's out of range or invalid
    }
    return newValue; // Accept the new value if it's valid
  }
}

class EditProfile extends StatefulWidget {
  final String userId;
  final String name;
  final String bio;
  final String profilePhotoUrl;
  final int booksGoal;
  final String email; // Add email parameter

  const EditProfile({
    super.key,
    required this.userId,
    required this.name,
    required this.bio,
    required this.profilePhotoUrl,
    required this.booksGoal,
    required this.email, // Accept email
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
  late String _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _bioController.text = widget.bio;
    _booksController.text = widget.booksGoal == 0 ? '' : widget.booksGoal.toString();
    _currentPhotoUrl = widget.profilePhotoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _booksController.dispose();
    super.dispose();
  }

  // Method to save profile
// Method to save profile
// Method to save profile
// Method to show the confirmation message
// Method to show the confirmation message
// Method to show the confirmation message
// Method to show the confirmation message
  void _showConfirmationMessage(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              Colors.transparent, // Make the dialog background transparent
          content: Container(
            width: 300, // Outer container width
            height: 200, // Outer container height
            decoration: const BoxDecoration(
              color: Colors.transparent, // Outer background transparent
            ),
            child: Center(
              child: Container(
                width: 280, // Match inner container size
                height: 120, // Match inner container size
                decoration: BoxDecoration(
                  color: Colors.lightGreen.withOpacity(
                      0.7), // Light green background with transparency
                  borderRadius: BorderRadius.circular(30), // Rounded corners
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle, // Checkmark icon
                      color: Colors.white,
                      size: 40, // Adjust size as needed
                    ),
                    const SizedBox(height: 10), // Space between icon and text
                    Text(
                      message,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18), // Change text color to white
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // Close the dialog after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close the dialog
    });
  }

// Method to save profile
  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final userId = widget.userId;
        String? profilePhotoUrl;

        // If a new image is picked, upload it
        if (_imageFile != null) {
          profilePhotoUrl = await _uploadProfilePhoto(userId);
          if (profilePhotoUrl == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload profile photo')),
            );
            return; // Exit the method if photo upload fails
          }
        } else if (_currentPhotoUrl.isNotEmpty &&
            _currentPhotoUrl != 'assets/images/profile_pic.png') {
          // Keep the current photo URL if no new photo is selected
          profilePhotoUrl = _currentPhotoUrl;
        } else {
          profilePhotoUrl = ''; // If no photo exists, set an empty string
        }

        // Prepare the profile data
        final userProfile = {
          'name': _nameController.text,
          'bio': _bioController.text,
          'books': _booksController.text.isEmpty
              ? 0
              : int.parse(_booksController.text),
          'profilePhoto': profilePhotoUrl,
          'email': widget.email,
        };

        // Show a confirmation dialog before saving the profile
        final confirmed = await _showConfirmationDialog();
        if (confirmed) {
          // Update the Firestore document
          await FirebaseFirestore.instance
              .collection('reader')
              .doc(userId)
              .set(userProfile, SetOptions(merge: true));

          // Show success message
          _showConfirmationMessage('Profile updated successfully!');

          // Delay before navigating back to give the user time to see the message
          await Future.delayed(const Duration(seconds: 2));

          // Return the updated data to the previous screen
          Navigator.pop(context, userProfile);
        }
      } catch (e) {
        print('Error saving profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }

// Method to handle the confirmation dialog
  Future<bool> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Changes'),
          content: const Text('Do you want to save the changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
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
            const SizedBox(height: 10),
            ProfilePhotoWidget(
              initialImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : _currentPhotoUrl.isNotEmpty
                      ? NetworkImage(_currentPhotoUrl)
                      : const AssetImage('assets/images/profile_pic.png'),
              onImagePicked: (File? imageFile) {
                setState(() {
                  _imageFile = imageFile;
                  if (imageFile == null) {
                    _currentPhotoUrl = '';
                  }
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
                    _buildTextField(
                      controller: _nameController,
                      hintText: "Name",
                      maxLength: 50,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _bioController,
                      hintText: "Bio",
                      maxLength: 152,
                      maxLines: 4,
                      optional: true, // Make bio optional
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _booksController,
                      hintText: "Yearly books goal (Max: 1000)",
                      keyboardType: TextInputType.number,
                       inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    CustomTextInputFormatter(),
  ],
                      optional: true, // Make this field optional
                    ),

                    const SizedBox(height: 40),
                    _buildEmailField(widget.email), // Add email field
                    const SizedBox(height: 40),
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
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color.fromARGB(
                255, 37, 30, 30), // Optional: Ensure the text is black
            fontWeight: FontWeight.bold, // Optional: Make the text bold
          ),
        ),
        backgroundColor: const Color(0xFFF8F8F3),
        centerTitle: true, // Center the title in the AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 47, 35, 35),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  // Custom method to build text fields with dynamic color changes
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLength = 0,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool optional = false, // Add optional parameter
  }) {
    bool isFocused = false;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          isFocused = hasFocus;
        });
      },
      child: TextFormField(
        controller: controller,
        maxLength: maxLength > 0 ? maxLength : null,
        maxLines: maxLines,
         onChanged: (text) {
    if (text.isEmpty) {
      _booksController.text = '';
    }
  },
 inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    CustomTextInputFormatter(),
  ],
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9B9B9B),
            fontSize: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide(
              color:
                  isFocused ? const Color(0xFF9B9B9B) : const Color(0xFFF790AD),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: const BorderSide(color: Color(0xFF9B9B9B)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: const BorderSide(color: Color(0xFFF790AD)),
          ),
        ),
        validator: (value) {
          if (!optional && (value == null || value.isEmpty)) {
            return 'Please enter your $hintText';
          }
          return null;
        },
      ),
    );
  }

  // New method for the unchangeable email field
  Widget _buildEmailField(String email) {
    return TextFormField(
      initialValue: email,
      readOnly: true,
      decoration: InputDecoration(
        hintText: "Email",
        hintStyle: const TextStyle(
          color: Color(0xFF9B9B9B),
          fontSize: 20,
        ),
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none, // No border
        ),
      ),
    );
  }
}

class ProfilePhotoWidget extends StatefulWidget {
  final ImageProvider<Object>? initialImage;
  final ValueChanged<File?> onImagePicked;

  const ProfilePhotoWidget({
    super.key,
    this.initialImage,
    required this.onImagePicked,
  });

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
    _currentImage = widget.initialImage ??
        const AssetImage('assets/images/profile_pic.png');
  }

  Future<void> _showImagePickerOptions(BuildContext context) async {
    bool isDefaultImage = _currentImage is AssetImage &&
        (_currentImage as AssetImage).assetName ==
            'assets/images/profile_pic.png';

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

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _currentImage = FileImage(_imageFile!);
      });
      widget.onImagePicked(_imageFile);
    }
  }

  void _deletePhoto() {
    setState(() {
      _imageFile = null;
      _currentImage = const AssetImage('assets/images/profile_pic.png');
    });
    widget.onImagePicked(null);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: _currentImage,
            backgroundColor: Colors.grey[300],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Color(0xFFF790AD)),
              onPressed: () {
                _showImagePickerOptions(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

