import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:folio/screens/SelectBookPage.dart';
import 'package:image_picker/image_picker.dart';

import 'custom_option_widget.dart'; // Import the custom widget

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

  TextEditingController _currentBookDetailsController = TextEditingController();
  String? _selectedBookId; // Variable to store the selected book ID
  String? _bookCover; // Variable to store the book cover URL
  String? _bookAuthor; // Variable to store the author name
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

// Function to show image picker options (Take a Photo, Choose from Gallery)

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomOptionWidget(
              icon: Icons.camera,
              title: 'Take a Photo',
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
            CustomOptionWidget(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 35),
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

// Upload the club picture if available in the _createClub method

// Club Image Picker with options

  // Function to create a new club
  // Function to create a new club
  Future<void> _createClub() async {
    // Check if the club name is empty or contains only whitespace
    if (_clubNameController.text.trim().isEmpty) {
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
      );

      if (user != null) {
        await _firestore.collection('clubs').add({
          'name': _clubNameController.text
              .trim(), // Ensure no leading/trailing spaces
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
          _selectedBookId = null; // Variable to store the selected book ID
          _bookCover = null; // Variable to store the book cover URL
          _bookAuthor = null;
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

    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      DateTime fullDateTime = DateTime(
        selectedDate!.year,
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

  // Function to pick an image

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
              // Club Name Field
              TextFormField(
                controller: _clubNameController,
                cursorColor: const Color(0xFFF790AD),
                maxLength: 30, // Limit input to 30 characters
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                      30), // Input formatter for character limit
                ],
                decoration: InputDecoration(
                  labelText: 'Club Name *',
                  labelStyle: const TextStyle(
                    color: Color(0xFF695555),
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                  ),
                  filled: true,
                  fillColor: Colors.white,
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
                  counterText:
                      '${_clubNameController.text.length}/30', // Character counter
                ),
                onChanged: (text) {
                  // This triggers the rebuild of the widget to update the counter text dynamically
                  setState(() {});
                },
              ),
              const SizedBox(height: 35),

// Description Field
              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 250, // Limit input to 250 characters
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                      250), // Input formatter to enforce character limit
                ],
                cursorColor: const Color(0xFFF790AD),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  alignLabelWithHint:
                      true, // Aligns label to the top when not focused
                  labelStyle: const TextStyle(
                    color: Color(0xFF695555),
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                  ),
                  filled: true,
                  fillColor: Colors.white,
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
                  counterText:
                      '${_descriptionController.text.length}/250', // Character counter
                ),
                onChanged: (text) {
                  // This triggers the rebuild of the widget to update the counter text dynamically
                  setState(() {});
                },
              ),
              const SizedBox(height: 35),
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
                  labelStyle: const TextStyle(
                    color: Color(0xFF695555),
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                  ),
                  filled: true,
                  fillColor: Colors.white,
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
                ),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey, // Customize the icon color if necessary
                ),
                dropdownColor:
                    Colors.white, // Customize the dropdown menu color
                menuMaxHeight: 200, // Set a max height for the dropdown menu
              ),
              const SizedBox(height: 35),

// Current Book Field
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(40), // Match the design
                        border: Border.all(
                            color: const Color(
                                0xFFF790AD)), // Match the border color
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _currentBookController.text.isNotEmpty
                                  ? _currentBookController.text
                                  : 'Select a Book',
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 18,
                                color: _currentBookController.text.isNotEmpty
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                              overflow:
                                  TextOverflow.ellipsis, // Truncate if too long
                            ),
                          ),
                          if (_currentBookController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.red), // X icon
                              onPressed: () {
                                setState(() {
                                  _currentBookController
                                      .clear(); // Clear the selected book title
                                  _bookCover = null; // Clear the book cover
                                  _bookAuthor = null; // Clear the author name
                                  _selectedBookId =
                                      null; // Clear the selected book ID
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // Space between text and button
                  ElevatedButton(
                    onPressed: () async {
                      // Navigate to SelectBookPage
                      final selectedBook = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectBookPage(),
                        ),
                      );

                      // Check if a book was selected
                      if (selectedBook != null) {
                        setState(() {
                          _selectedBookId = selectedBook['id']; // Store book ID
                          _currentBookController.text =
                              selectedBook['title']; // Set book title
                          _bookCover = selectedBook[
                              'coverImage']; // Store book cover URL
                          _bookAuthor =
                              selectedBook['author']; // Store author name
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFF790AD), // Customize button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

// Display the selected book cover and author
              if (_bookCover != null) ...[
                const SizedBox(height: 16), // Space between fields
                Image.network(
                  _bookCover!,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                          Icons.error), // Error icon if the image fails to load
                    );
                  },
                ),
              ],

              const SizedBox(height: 20),

              // Next Discussion Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Next Discussion (Optional):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDiscussionDate,
                    child: Text(
                      _discussionDate != null
                          ? _formatTimestamp(_discussionDate!)
                          : 'Pick a date & time',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFF790AD),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
                            borderRadius: BorderRadius.circular(40),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Create Club',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 30),
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
