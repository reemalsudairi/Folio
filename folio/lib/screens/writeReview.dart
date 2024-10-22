import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // For star rating
import 'package:http/http.dart' as http;
import 'dart:convert';

class WriteReviewPage extends StatefulWidget {
  final String userId;
  final String bookId;

  WriteReviewPage({required this.userId, required this.bookId});

  @override
  _WriteReviewPageState createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  String bookTitle = '';
  String bookAuthor = '';
  String bookCoverUrl = '';
  double rating = 0;
  final TextEditingController reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBookDetails();
  }

  // Fetch book details from Google Books API
  Future<void> fetchBookDetails() async {
    final url = 'https://www.googleapis.com/books/v1/volumes/${widget.bookId}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        bookTitle = data['volumeInfo']['title'] ?? 'Unknown Title';
        bookAuthor = data['volumeInfo']['authors'] != null
            ? data['volumeInfo']['authors'][0]
            : 'Unknown Author';
        bookCoverUrl = data['volumeInfo']['imageLinks'] != null
            ? data['volumeInfo']['imageLinks']['thumbnail']
            : '';
      });
    }
  }

void _showReviewPublishMessage() {
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
              'Review Published Successfully!',
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

  // Automatically close the confirmation dialog after 2 seconds and navigate back
  Future.delayed(const Duration(seconds: 2), () {
    Navigator.of(context).pop(); // Close the confirmation dialog
    Navigator.of(context).pop();
  });
}

// Store review in Firestore
Future<void> submitReview() async {
  await FirebaseFirestore.instance.collection('reviews').add({
    'createdAt': FieldValue.serverTimestamp(), // This will add the current server time
    'reader_id': widget.userId,
    'bookID': widget.bookId,
    'rating': rating,
    'reviewText': reviewController.text,
  });

  _showReviewPublishMessage(); // Show success message after submission
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
     backgroundColor: const Color(0xFFF8F8F3), // Set background color to white
      appBar: AppBar(
        title: const Text(
          'Write a Review',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Color(0xFF351F1F),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8F8F3),
        elevation: 0,
leading: IconButton(
  icon: Icon(Icons.arrow_back, color: Colors.black),
  onPressed: () {
    _showExitConfirmationDialog().then((confirm) {
      if (confirm == true) {
        Navigator.pop(context); // Go back if confirmed
      }
    });
  },
),

  // Setting the toolbar height to ensure title is centered properly
  toolbarHeight: 70, // You can adjust this height as needed
),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center horizontally
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bookCoverUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            bookCoverUrl,
                            height: 220, // Increased height
                            width: 150,  // Increased width
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          height: 220,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookTitle,
                          style: TextStyle(
                            fontSize: 30,  // Increased font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12), // Space between title and author
                        Text(
                          'By $bookAuthor',
                          style: TextStyle(
                            fontSize: 22,  // Increased font size
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Keep them in a row but centered
                children: [
                  Text(
                    'Rate it',
                    style: TextStyle(
                      fontSize: 24,  // Increased size for "Rate it" text
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 12),
RatingBar.builder(
  initialRating: 0,
  minRating: 0,
  direction: Axis.horizontal,
  allowHalfRating: true,
  itemCount: 5,
  itemPadding: EdgeInsets.symmetric(horizontal: 1.0),
  itemBuilder: (context, _) => Icon(
    Icons.star_rounded, // Always use the filled star icon
    color: rating > 0 ? Color(0xFFF790AD) : Colors.grey[350], // Pink for filled stars, gray for unfilled stars
    size: 50, // Bigger star size
  ),
  itemSize: 50, // Bigger star size
  unratedColor:  Colors.grey[350], // No unrated color needed as we handle color directly in the itemBuilder
  onRatingUpdate: (newRating) {
    setState(() {
      rating = newRating;
    });
  },
),



                ],
              ),
            ),
            SizedBox(height: 30),

TextField(
  controller: reviewController,
  maxLines: 5,
  maxLength: 300, // Set max character limit
  inputFormatters: [
    FilteringTextInputFormatter.deny(RegExp(r'^\s*$')), // Prevent whitespace-only input
  ],
  decoration: InputDecoration(
    hintText: 'What do you think of this book?',
    hintStyle: TextStyle(color: Colors.grey[500]),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15.0),
      borderSide: BorderSide(color: Color(0xFFF790AD)), // Pink border by default
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15.0),
      borderSide: BorderSide(color: Color(0xFFF790AD)), // Pink border even before focus
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15.0),
      borderSide: BorderSide(color: Color(0xFFF790AD)), // Pink border on focus
    ),
  ),
  onChanged: (value) {
    // Optionally, you can provide real-time feedback if needed
    if (value.trim().isEmpty) {
      // You could show an error message here if needed
    }
  },
),
            SizedBox(height: 40),  // Space above the Send button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF790AD), // Pink color for the button
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30), // Increased button padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _showReviewConfirmationDialog,
                child: Text(
                  'Publish review',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewConfirmationDialog() {
  showDialog(
    context: context,
    barrierDismissible: false, // Disable dismissal by clicking outside
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF790AD).withOpacity(0.9), // Pinkish background with opacity
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.rate_review, // Icon for review confirmation
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              'Are you sure you want to publish this review? You need to delete this review to publish another one.',
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
                    Navigator.of(context).pop(); // Close the dialog
                    submitReview(); // Call the submitReview function
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(
                                    255, 131, 201, 133), // Red background for "Yes"
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
                    backgroundColor: Colors.grey, // Grey background for "No"
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
  // Show confirmation dialog for back button
Future<bool?> _showExitConfirmationDialog() async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // Disable dismissal by clicking outside
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF790AD).withOpacity(0.9), // Pinkish background with opacity
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning, // Warning icon
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              'You will lose this review. Are you sure you want to go back?',
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
                    Navigator.of(context).pop(true); // Close the dialog and return true
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 245, 114, 105), // Pink background for "Yes"
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
                    Navigator.of(context).pop(false); // Close the dialog and return false
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey, // Grey background for "No"
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
}



