import 'dart:io';

import 'package:flutter/material.dart';
import 'package:folio/screens/homePage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Handle save action
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const HomePage()), // Navigate to HomePage if skipping
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : const AssetImage('assets/avatar.png') as ImageProvider,
                child: const Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Name'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Username'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Bio'),
            ),
            // Add more fields as needed
          ],
        ),
      ),
    );
  }
}
