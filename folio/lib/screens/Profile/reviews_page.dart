import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/book_details_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReviewsPage extends StatelessWidget {
  final String readerId; // Current user's uid
  final String currentUserId; // Current user's ID

  ReviewsPage({required this.readerId, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3), // Set background color
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('reader_id', isEqualTo: readerId) // Filter reviews by reader_id
            .orderBy('rating', descending: true) // Order by rating
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No reviews yet'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;

              return ReviewTile(
                reviewText: data['reviewText'],
                rating: data['rating'] is int
                    ? (data['rating'] as int).toDouble()
                    : (data['rating'] is double)
                        ? (data['rating'] as double)
                        : double.tryParse(data['rating']) ?? 0.0, // Handle string case
                bookID: data['bookID'],
                reviewId: document.id,
                readerId: data['reader_id'], // This is the review's reader ID
                isOwner: data['reader_id'] == currentUserId, // Pass the isOwner flag based on current user
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
class ReviewTile extends StatelessWidget {
  final String reviewText;
  final double rating;
  final String bookID;
  final String reviewId;
  final String readerId;
  final bool isOwner;

  ReviewTile({
    required this.reviewText,
    required this.rating,
    required this.bookID,
    required this.reviewId,
    required this.readerId,
    required this.isOwner,
  });

  // Function to delete a review with confirmation dialog
  void _deleteReview(BuildContext context) {
    _showRemoveConfirmation(context);
  }

  // Function to show the confirmation dialog
  void _showRemoveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Disable dismissal by clicking outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF790AD).withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.exit_to_app,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to delete this review?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center the buttons
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 245, 114, 105),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: const Size(100, 40),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      _removeReview(context); // Remove the review if confirmed
                    },
                    child: const Text(
                      'Yes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12), // Space between buttons
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: const Size(100, 40),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog without action
                    },
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

  // Function to remove the review
  void _removeReview(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();
      // Show confirmation message
      _showConfirmationMessage(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete review: $e')),
      );
    }
  }

  // Function to show the "Review Removed Successfully!" message
  void _showConfirmationMessage(BuildContext context) {
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
              Text(
                'Review Removed Successfully!',
                style: const TextStyle(
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
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('reader').doc(readerId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while data is being fetched
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text("User data not found"));
        }

        Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
        String username = userData['name'] ?? 'Anonymous';
        String profilePic = userData['profilePhoto'] ?? 'assets/profile_pic.png';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Card(
            elevation: 2,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: profilePic.startsWith('http')
                        ? NetworkImage(profilePic)
                        : AssetImage(profilePic) as ImageProvider,
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: List.generate(5, (index) {
                            if (rating >= index + 1) {
                              return Icon(
                                Icons.star,
                                color: const Color(0xFFF790AD),
                                size: 18,
                              );
                            } else if (rating >= index + 0.5) {
                              return Icon(
                                Icons.star_half,
                                color: const Color(0xFFF790AD),
                                size: 18,
                              );
                            } else {
                              return Icon(
                                Icons.star_border,
                                color: const Color(0xFFF790AD),
                                size: 18,
                              );
                            }
                          }),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          reviewText,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10), // Space between review text and book cover
                  Column(
                    children: [
                      if (isOwner) // Conditionally render the delete button
                        IconButton(
                          icon: Icon(Icons.delete, color: const Color.fromARGB(255, 245, 114, 105)),
                          onPressed: () => _deleteReview(context),
                        ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailsPage(
                                bookId: bookID, // Pass bookID
                                userId: readerId, // Pass userID (readerId)
                              ),
                            ),
                          );
                        },
                        child: BookCover(bookID: bookID),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


class BookCover extends StatefulWidget {
  final String bookID;

  BookCover({required this.bookID});

  @override
  _BookCoverState createState() => _BookCoverState();
}

class _BookCoverState extends State<BookCover> {
  Map<String, dynamic>? bookDetails;

  @override
  void initState() {
    super.initState();
    _fetchBookDetails();
  }

  // Fetch book details
  void _fetchBookDetails() async {
    var response = await http.get(Uri.parse('https://www.googleapis.com/books/v1/volumes/${widget.bookID}'));
    if (response.statusCode == 200) {
      setState(() {
        bookDetails = json.decode(response.body);
      });
    } else {
      // Handle error
      setState(() {
        bookDetails = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = bookDetails?['volumeInfo']['imageLinks']['thumbnail'] ?? '';
    String title = bookDetails?['volumeInfo']['title'] ?? 'Unknown Title';

    return Container(
      width: 40, // Set a fixed width for the book cover
      height: 60, // Set a fixed height for the book cover
      child: imageUrl.isNotEmpty
          ? Image.network(imageUrl, fit: BoxFit.cover)
          : Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(child: Text(title, style: TextStyle(fontSize: 10), textAlign: TextAlign.center)), // Show title if no image
            ),
    );
  }
}
