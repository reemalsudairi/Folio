import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateClubPage extends StatefulWidget {
  const CreateClubPage({super.key});

  @override
  _CreateClubPageState createState() => _CreateClubPageState();
}

class _CreateClubPageState extends State<CreateClubPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _clubNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _currentBookController = TextEditingController();
  Timestamp? _discussionDate;

  File? _clubImageFile;
  String? _clubImageUrl;
  bool _isLoading = false;
  String? _selectedLanguage;
  String? _errorMessage;

  // List of popular languages including Arabic
  final List<String> _languages = [
    'English',
    'Spanish',
    'Mandarin',
    'French',
    'German',
    'Arabic',
    'Russian',
    'Portuguese',
    'Hindi',
    'Japanese',
  ];

  // Function to create a new club
  Future<void> _createClub() async {
    if (_clubNameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a club name.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Reset error message
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      // Upload the club picture if available
      if (_clubImageFile != null) {
        final ref = _storage
            .ref()
            .child('club_pictures')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_clubImageFile!);
        _clubImageUrl = await ref.getDownloadURL();
      }

      if (user != null) {
        await _firestore.collection('clubs').add({
          'name': _clubNameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'discussionDate': _discussionDate,
          'language': _selectedLanguage ?? '',
          'currentBookID': _currentBookController.text.trim(),
          'ownerID': user.uid,
          'picture':
              _clubImageUrl ?? '', // Add the club picture URL if available
        });

        // Show success message
        _showConfirmationMessage();

        // Clear the form
        _clubNameController.clear();
        _descriptionController.clear();
        _currentBookController.clear();
        setState(() {
          _discussionDate = null;
          _clubImageFile = null;
          _selectedLanguage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error creating club. Please try again.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to show confirmation message
  void _showConfirmationMessage() {
    showDialog(
      context: context,
      barrierDismissible: false, // Disable dismissal by clicking outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.lightGreen.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                'Club Created Successfully!',
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

    // Automatically close the confirmation dialog after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close the confirmation dialog
    });
  }

  // Function to select a date and time for the next discussion
  Future<void> _pickDiscussionDate() async {
    DateTime now = DateTime.now();

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now, // Prevent selecting a past date
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        DateTime fullDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        if (fullDateTime.isBefore(DateTime.now())) {
          setState(() {
            _errorMessage = 'You cannot select a past time.';
          });
        } else {
          setState(() {
            _discussionDate = Timestamp.fromDate(fullDateTime);
          });
        }
      }
    }
  }

  // Function to show image picker options (Take a Photo, Choose from Gallery)
  Future<void> _showImagePickerOptions() async {
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

  // Function to pick an image
  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await ImagePicker().pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _clubImageFile = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      appBar: AppBar(
        title: const Text(
          'Create a Club',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Color(0xFF351F1F),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8F8F3),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Club Image Picker with options
              Center(
                child: GestureDetector(
                  onTap: _showImagePickerOptions, // Show picker options on tap
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _clubImageFile != null
                        ? FileImage(_clubImageFile!)
                        : const AssetImage('assets/images/placeholder.png')
                            as ImageProvider,
                    child: _clubImageFile == null
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Error message display
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

              // Club Name Field
              TextFormField(
                controller: _clubNameController,
                decoration: InputDecoration(
                  labelText: 'Club Name *',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Language dropdown menu
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                items: _languages.map((String language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(language),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLanguage = newValue;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Language (Optional)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey, // Customize the icon color if necessary
                ),
                dropdownColor:
                    Colors.white, // Customize the dropdown menu color
                menuMaxHeight: 200, // Set a max height for the dropdown menu
              ),

              const SizedBox(height: 20),

              // Current Book Field
              TextFormField(
                controller: _currentBookController,
                decoration: InputDecoration(
                  labelText: 'Current Book (Optional)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Next Discussion Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Next Discussion (Optional):',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDiscussionDate,
                    child: Text(
                      _discussionDate != null
                          ? _formatTimestamp(_discussionDate!)
                          : 'Pick a date & time',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFF790AD),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Create Club Button with loading spinner
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createClub,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF790AD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Create Club',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  // Format Firestore timestamp to readable date
  String _formatTimestamp(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    return '${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute}';
  }
}
