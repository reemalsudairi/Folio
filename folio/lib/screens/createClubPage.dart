import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:folio/screens/SelectBookPage.dart';
import 'package:folio/screens/viewClub.dart';
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
  late ImageProvider<Object> _currentImage;

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

  @override
  void initState() {
    super.initState();
    // Set the default image to 'assets/images/clubs.jpg'
    _currentImage = const AssetImage('assets/images/clubs.jpg');
  }

  // Function to show options for picking an image
  Future<void> _showImagePickerOptions(BuildContext context) async {
    // Check if the current image is the default image
    bool isDefaultImage = _clubImageFile == null;

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 50.0),
        child: Wrap(
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
    );
  }

  // Function to pick an image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        setState(() {
          _clubImageFile = File(pickedImage.path);
          _currentImage = FileImage(_clubImageFile!);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to pick image. Please try again.";
      });
    }
  }

  // Function to delete the selected photo and revert to the default image
  void _deletePhoto() {
    setState(() {
      _clubImageFile = null;
      _currentImage = const AssetImage('assets/images/clubs.jpg');
    });
    // If you have a callback to notify parent widget, uncomment the line below
    // widget.onImagePicked(null);
  }

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

      if (user != null) {
        // Create the club and get the DocumentReference
        DocumentReference clubRef = await _firestore.collection('clubs').add({
          'name': _clubNameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'language': _selectedLanguage ?? '',
          'currentBookID': _selectedBookId ?? '', // Store book ID
          'ownerID': user.uid,
          'picture': _clubImageUrl ?? null, // Club picture URL
          if (_selectedBookId != null && _discussionDate != null)
            'discussionDate': _discussionDate,
        });

        // Show success message
        _showConfirmationMessage();

        // Delay the navigation to allow the confirmation message to be displayed
        await Future.delayed(const Duration(seconds: 2)); // 2-second delay

        // Navigate to the View Club page, passing the club ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewClub(clubId: clubRef.id, fromCreate: true,),
          ),
        );

        // Clear the form
        _clubNameController.clear();
        _descriptionController.clear();
        _currentBookController.clear();

        setState(() {
          _discussionDate = null;
          _clubImageFile = null;
          _currentImage = const AssetImage(
              'assets/images/clubs.jpg'); // Revert to default image
          _selectedLanguage = null;
          _selectedBookId = null; // Clear the selected book ID
          _bookCover = null; // Clear the book cover URL
          _bookAuthor = null; // Clear the author name
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error creating club: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateClubConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false, // Disable dismissal by clicking outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF790AD)
                .withOpacity(0.9), // Pinkish background with opacity
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.group_add, // Icon for creating a club
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to create the club?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _createClub();
                      // Call the confirmation message function
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(
                          255, 131, 201, 133), // Green background for "Yes"
                    ),
                    child: const Text(
                      'Yes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(
                          255, 245, 114, 105), // Green background for "Yes"
                    ),
                    child: const Text(
                      'No',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

    if (selectedDate == null) return; // User canceled the date picker

    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime == null) return; // User canceled the time picker

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

  // Format Firestore timestamp to readable date
  String _formatTimestamp(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)} '
        '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  // Helper function to ensure two digits
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

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
// Club Image Picker with options
              Center(
                child: GestureDetector(
                  onTap: () => _showImagePickerOptions(context),
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(10), // Border radius 10
                          border: Border.all(
                              color: Colors.grey, width: 2), // Add border
                          image: DecorationImage(
                            image: _clubImageFile != null
                                ? FileImage(_clubImageFile!) as ImageProvider
                                : const AssetImage(
                                    'assets/images/clubs.jpg'), // Placeholder image
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.camera_alt,
                            color: Color(0xFFF790AD)),
                        onPressed: () => _showImagePickerOptions(
                            context), // Open the image picker options
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Error message display
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
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
                  setState(() {
                    // Prevent leading whitespaces by trimming only at the start
                    if (text.startsWith(' ')) {
                      _clubNameController.text = text.trimLeft();
                      _clubNameController.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: _clubNameController.text.length),
                      );
                    }
                  });
                },
              ),

              const SizedBox(height: 35),

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
                  setState(() {
                    // Prevent leading whitespaces by trimming only at the start
                    if (text.startsWith(' ')) {
                      _descriptionController.text = text.trimLeft();
                      _descriptionController.selection =
                          TextSelection.fromPosition(
                        TextPosition(
                            offset: _descriptionController.text.length),
                      );
                    }
                  });
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

              Column(
                children: [
// Current Book Field with custom styling
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            // Navigate to SelectBookPage when the container is tapped
                            final selectedBook = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelectBookPage(),
                              ),
                            );

                            // Check if a book was selected
                            if (selectedBook != null) {
                              setState(() {
                                _selectedBookId =
                                    selectedBook['id']; // Store book ID
                                _currentBookController.text =
                                    selectedBook['title']; // Set title
                                _bookCover = selectedBook[
                                    'coverImage']; // Store book cover
                                _bookAuthor =
                                    selectedBook['author']; // Store author name
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(40), // Match the design
                              border: Border.all(
                                  color:
                                      const Color(0xFFF790AD)), // Border color
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
                                      color:
                                          _currentBookController.text.isNotEmpty
                                              ? Colors.black
                                              : Colors.grey,
                                    ),
                                    overflow: TextOverflow
                                        .ellipsis, // Truncate if too long
                                  ),
                                ),
                                // Search icon
                                const Icon(
                                  Icons.search,
                                  color:
                                      Color(0xFFF790AD), // Customize icon color
                                ),
                                if (_currentBookController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red), // X icon
                                    onPressed: () {
                                      setState(() {
                                        _currentBookController
                                            .clear(); // Clear the book title
                                        _bookCover =
                                            null; // Clear the book cover
                                        _bookAuthor =
                                            null; // Clear the author name
                                        _selectedBookId =
                                            null; // Clear the book ID
                                        _discussionDate =
                                            null; // Clear the discussion date
                                      });
                                    },
                                  ),
                              ],
                            ),
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
                          child: Icon(Icons
                              .error), // Error icon if the image fails to load
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _bookAuthor != null ? 'Author: $_bookAuthor' : '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),

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
                    onPressed:
                        _selectedBookId != null ? _pickDiscussionDate : null,
                    child: Text(
                      _discussionDate != null
                          ? _formatTimestamp(_discussionDate!)
                          : _selectedBookId != null
                              ? 'Pick a date & time'
                              : 'Select a book first',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedBookId != null
                            ? const Color(0xFFF790AD)
                            : Colors
                                .grey, // Disable color if no book is selected
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
// Create Club Button with loading spinner
              // Create Club Button with loading spinner
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Check if the club name is empty or contains only whitespace
                          if (_clubNameController.text.trim().isEmpty) {
                            setState(() {
                              _errorMessage =
                                  'Please enter a club name.'; // Set error message
                            });
                            return; // Return early if there's an error
                          }
                          _showCreateClubConfirmation(); // Show confirmation dialog if name is valid
                        },
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

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}