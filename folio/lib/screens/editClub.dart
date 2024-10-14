import 'dart:io'; // For handling File images

import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore interaction
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Authentication
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:folio/screens/SelectBookPage.dart'; // Ensure you import the SelectBookPage
import 'package:image_picker/image_picker.dart'; // Import the image picker package

class EditClub extends StatefulWidget {
  final String clubId; // Pass the clubId to identify the club being edited

  const EditClub({Key? key, required this.clubId}) : super(key: key);

  @override
  _EditClubPageState createState() => _EditClubPageState();
}

class _EditClubPageState extends State<EditClub> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _clubNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _currentBookController = TextEditingController();
  bool _isLoading = false;
  String? _selectedLanguage;
  String? _selectedBookId;
  String? _bookCover;
  String? _bookAuthor;
  Timestamp? _discussionDate;
  String? _errorMessage;
  String? _clubImageUrl; // Store the club image URL
  File? _clubImageFile; // Local image file for new uploads
  final ImagePicker _picker = ImagePicker(); // Create an ImagePicker instance
  String? _originalClubImageUrl;

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
    _loadClubData(); // Load the club data when the page is initialized
  }

  // Function to load the existing club data for editing
  Future<void> _loadClubData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Fetching club data from Firestore...');
      DocumentSnapshot clubSnapshot =
          await _firestore.collection('clubs').doc(widget.clubId).get();

      if (clubSnapshot.exists) {
        var clubData = clubSnapshot.data() as Map<String, dynamic>;
        print('Club data retrieved: $clubData');

        _clubNameController.text = clubData['name'] ?? '';
        _descriptionController.text = clubData['description'] ?? '';
        _selectedLanguage =
            _languages.contains(clubData['language']) ? clubData['language'] : null; // Ensure language is valid
        _currentBookController.text = clubData['currentBookTitle'] ?? '';
        _selectedBookId = clubData['currentBookID'];
        _bookCover = clubData['currentBookCover'];
        _bookAuthor = clubData['currentBookAuthor'];
        _discussionDate = clubData['discussionDate'];
        _clubImageUrl = clubData['picture']; // Load the existing club image URL
        _originalClubImageUrl = clubData['picture']; // Track the original image URL

        print('Club image URL: $_clubImageUrl');
      } else {
        print('Club document does not exist.');
        setState(() {
          _errorMessage = 'Club not found.';
        });
      }
    } catch (e) {
      print('Error fetching club data: $e');
      setState(() {
        _errorMessage = 'Failed to load club data. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Function to show options for picking an image
Future<void> _showImagePickerOptions(BuildContext context) async {
  // Determine if the current image is the default image
  bool isDefaultImage = _clubImageUrl == null && _clubImageFile == null;

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
                Navigator.of(context).pop(); // Close the bottom sheet
                _deleteClubImage(); // Update the local state to show default image
              },
            ),
        ],
      ),
    ),
  );
}


// Function to delete the current club image (only locally)
void _deleteClubImage() {
  setState(() {
    _clubImageUrl = null; // Set to null to show the default image
    _clubImageFile = null; // Clear any selected image file
  });
  // Changes are now pending and will be saved when 'Update Club' is pressed
}




  // Function to pick an image
  Future<void> _pickImage(ImageSource source) async {
    try {
      print('Picking image from $source...');
      final pickedImage = await _picker.pickImage(source: source);
      if (pickedImage != null) {
        setState(() {
          _clubImageFile = File(pickedImage.path);
          _clubImageUrl = null; // Reset the URL as a new image is selected
        });
        print('Image selected: ${pickedImage.path}');
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _errorMessage = "Failed to pick image. Please try again.";
      });
    }
  }

  // Function to upload a new image
  Future<String?> _uploadImage() async {
    if (_clubImageFile == null) {
      print('No new image to upload.');
      return _clubImageUrl; // Return existing URL if no new image
    }

    try {
      String fileName =
          'club_pictures/${widget.clubId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('Uploading image to Firebase Storage with path: $fileName');
      Reference storageRef = _storage.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(_clubImageFile!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Image uploaded successfully. Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        _errorMessage = 'Failed to upload image. Please try again.';
      });
      return null;
    }
  }

// Function to update the club details
Future<void> _updateClub() async {
  // Validate club name
  if (_clubNameController.text.trim().isEmpty) {
    setState(() {
      _errorMessage = 'Club name is required.';
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    print('Starting update process...');

    // Initialize imageUrl with existing _clubImageUrl
    String? imageUrl = _clubImageUrl;

    // If a new image is selected, upload it
    if (_clubImageFile != null) {
      print('Uploading new image...');
      imageUrl = await _uploadImage(); // Upload the new image
      if (imageUrl == null) {
        throw Exception('Image upload failed');
      }
    }

    // If the image was deleted (i.e., _clubImageUrl is null and there was an original image)
    bool isImageDeleted = _originalClubImageUrl != null && _clubImageUrl == null;
    if (isImageDeleted) {
      print('Deleting existing image from Firebase...');
      await _deleteImageFromFirebase(); // Delete the image from Firebase Storage
    }

    // Prepare the data to update
    Map<String, dynamic> updateData = {
      'name': _clubNameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'language': _selectedLanguage ?? '',
      'currentBookID': _selectedBookId ?? '',
      'currentBookTitle': _currentBookController.text.trim(),
      'currentBookCover': _bookCover ?? '',
      'currentBookAuthor': _bookAuthor ?? '',
      'discussionDate': _discussionDate,
    };

    if (imageUrl != null && imageUrl.isNotEmpty) {
      updateData['picture'] = imageUrl;
      print('Adding picture URL to updateData.');
    } else if (isImageDeleted) {
      updateData['picture'] = FieldValue.delete(); // Remove the picture field
      print('Removing picture URL from updateData.');
    }

    print('Updating Firestore document...');
    await _firestore.collection('clubs').doc(widget.clubId).update(updateData);
    print('Firestore update successful.');

    // Show success message
    _showConfirmationMessage();

    // Optionally, navigate back or refresh data
    Navigator.pop(context);
  } catch (e) {
    print('Error updating club: $e');
    setState(() {
      _errorMessage = 'Failed to update club. Please try again.';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

// Helper function to delete image from Firebase Storage
Future<void> _deleteImageFromFirebase() async {
  if (_originalClubImageUrl == null) {
    // No image to delete
    return;
  }

  try {
    print('Deleting image from Firebase Storage...');
    Uri uri = Uri.parse(_originalClubImageUrl!);
    String fullPath = uri.path; // e.g., /v0/b/<bucket>/o/<path>
    String storagePath =
        fullPath.split('/o/').last.split('?').first.replaceAll('%2F', '/');
    print('Extracted storage path: $storagePath');

    Reference storageRef = _storage.ref().child(storagePath);
    await storageRef.delete();
    print('Image deleted from Firebase Storage.');
  } catch (e) {
    print('Error deleting image from Firebase Storage: $e');
    throw e; // Propagate the error to be handled in _updateClub
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
                'Club Updated Successfully!',
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

    if (selectedDate == null) {
      print('Date picker canceled.');
      return; // User canceled the date picker
    }

    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime == null) {
      print('Time picker canceled.');
      return; // User canceled the time picker
    }

    DateTime fullDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (fullDateTime.isBefore(DateTime.now())) {
      print('Selected date is in the past.');
      setState(() {
        _errorMessage = 'You cannot select a past time.';
      });
    } else {
      setState(() {
        _discussionDate = Timestamp.fromDate(fullDateTime);
        print('Selected discussion date: $_discussionDate');
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
          'Edit Club',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Color(0xFF351F1F),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8F8F3),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _showDeleteConfirmationDialog,
            child: const Text(
              'Delete Club',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                borderRadius: BorderRadius.circular(10), // Border radius 10
                                border:
                                    Border.all(color: Colors.grey, width: 2), // Add border
                                image: DecorationImage(
                                  image: _clubImageFile != null
                                      ? FileImage(_clubImageFile!) as ImageProvider
                                      : (_clubImageUrl != null
                                          ? NetworkImage(_clubImageUrl!)
                                          : const AssetImage('assets/images/clubs.jpg') as ImageProvider),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            IconButton(
                              icon: const Icon(Icons.camera_alt,
                                  color: Color(0xFFF790AD)),
                              onPressed: () => _showImagePickerOptions(context), // Open the image picker options
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
                        LengthLimitingTextInputFormatter(30), // Input formatter for character limit
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
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      maxLength: 250, // Limit input to 250 characters
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(250), // Input formatter to enforce character limit
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

                    // Current Book Field with custom styling
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
                                  color: const Color(0xFFF790AD)), // Border color
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
                                    overflow: TextOverflow.ellipsis, // Truncate if too long
                                  ),
                                ),
                                // Search icon
                                GestureDetector(
                                  onTap: () async {
                                    print('Navigating to SelectBookPage...');
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
                                        _currentBookController.text = selectedBook['title']; // Set title
                                        _bookCover = selectedBook['coverImage']; // Store book cover
                                        _bookAuthor = selectedBook['author']; // Store author name
                                      });
                                      print('Book selected: $selectedBook');
                                    } else {
                                      print('No book selected.');
                                    }
                                  },
                                  child: const Icon(
                                    Icons.search,
                                    color: Color(0xFFF790AD), // Customize icon color
                                  ),
                                ),
                                if (_currentBookController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red), // X icon
                                    onPressed: () {
                                      setState(() {
                                        _currentBookController.clear(); // Clear the book title
                                        _bookCover = null; // Clear the book cover
                                        _bookAuthor = null; // Clear the author name
                                        _selectedBookId = null; // Clear the book ID
                                      });
                                      print('Book selection cleared.');
                                    },
                                  ),
                              ],
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
                            child: Icon(Icons.error), // Error icon if the image fails to load
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

                    // Update Club Button with loading spinner
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _updateClub,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF790AD),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Update Club',
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

  // Function to show delete confirmation dialog for the club
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Club'),
          content: const Text(
              'Are you sure you want to delete this club? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deleteClub(); // Delete the club
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to delete the club from Firebase
  Future<void> _deleteClub() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Deleting club with ID: ${widget.clubId}');

      // If the image is stored in Firebase Storage, delete it
      if (_clubImageUrl != null) {
        print('Deleting club image from Firebase Storage...');
        Uri uri = Uri.parse(_clubImageUrl!);
        String fullPath = uri.path; // e.g., /v0/b/<bucket>/o/<path>
        String storagePath =
            fullPath.split('/o/').last.split('?').first.replaceAll('%2F', '/');
        print('Extracted storage path for club image: $storagePath');

        Reference storageRef = _storage.ref().child(storagePath);
        await storageRef.delete();
        print('Club image deleted from Firebase Storage.');
      }

      // Delete the Firestore document
      print('Deleting club document from Firestore...');
      await _firestore.collection('clubs').doc(widget.clubId).delete();
      print('Club document deleted from Firestore.');

      // Show deletion confirmation message
      _showClubDeletionMessage();

      // Optionally, navigate back or perform other actions as needed
      Navigator.pop(context);
    } catch (e) {
      print('Error deleting club: $e');
      setState(() {
        _errorMessage = 'Failed to delete club. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to show club deletion confirmation message
  void _showClubDeletionMessage() {
    showDialog(
      context: context,
      barrierDismissible: false, // Disable dismissal by clicking outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                'Club Deleted Successfully!',
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
}
