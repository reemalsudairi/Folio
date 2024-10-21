import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Add this for star rating
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

  // Store review in Firestore
  Future<void> submitReview() async {
    await FirebaseFirestore.instance.collection('reviews').add({
      'reader_id': widget.userId,
      'bookID': widget.bookId,
      'rating': rating,
      'reviewText': reviewController.text,
    });
    Navigator.pop(context); // Go back after submitting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Write a review'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                bookCoverUrl.isNotEmpty
                    ? Image.network(bookCoverUrl, height: 100, width: 70)
                    : Container(height: 100, width: 70, color: Colors.grey),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('By $bookAuthor'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('Rate it'),
            SizedBox(height: 8),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Color(0xFFF790AD), // Pink color for stars
              ),
              onRatingUpdate: (newRating) {
                setState(() {
                  rating = newRating;
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write your review on the book',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF790AD), // Pink color for button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: submitReview,
                child: Text('Send'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
