import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/book_details_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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
            .where('reader_id',
                isEqualTo: readerId) // Filter reviews by reader_id
            .orderBy('createdAt',
                descending: true) // Order by timestamp instead of rating
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error} Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No reviews yet'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;

              return ReviewTile(
                reviewText: data['reviewText'],
                rating: data['rating'] is int
                    ? (data['rating'] as int).toDouble()
                    : (data['rating'] is double)
                        ? (data['rating'] as double)
                        : double.tryParse(data['rating']) ??
                            0.0, // Handle string case
                bookID: data['bookID'],
                reviewId: document.id,
                readerId: data['reader_id'], // This is the review's reader ID
                isOwner: data['reader_id'] ==
                    currentUserId, // Pass the isOwner flag based on current user
                createdAt: data['createdAt'], // Pass createdAt timestamp
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
  final Timestamp createdAt;

  ReviewTile({
    required this.reviewText,
    required this.rating,
    required this.bookID,
    required this.reviewId,
    required this.readerId,
    required this.isOwner,
    required this.createdAt,
  });

// Function to calculate time ago
  String timeAgo(Timestamp timestamp) {
    final DateTime now = DateTime.now();
    final DateTime reviewTime = timestamp.toDate();
    final Duration difference = now.difference(reviewTime);

    if (difference.inDays > 7) {
      int weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inSeconds} second${difference.inSeconds > 1 ? 's' : ''} ago';
    }
  }

 

void _confirmDeleteReview(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 245, 114, 105),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: const Size(100, 40),
                  ),
                  onPressed: () async {
                    // Attempt to delete the review
                    bool isDeleted = await _deleteReview(context);

                    // Close the confirmation dialog
                    Navigator.of(context).pop();

                    if (isDeleted) {
                      // Show success message after confirmation dialog is closed
                      _showSuccessfulMessage(context);
                    } else {
                      // Handle failure to delete (optional)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete review.')),
                      );
                    }
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
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: const Size(100, 40),
                  ),
                  onPressed: () {
                    Navigator.of(context)
                        .pop(); // Close the dialog without action
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

Future<bool> _deleteReview(BuildContext context) async {
  try {
    // Attempt to delete the review from Firestore
    var snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('bookID', isEqualTo: bookID)
        .where('reader_id', isEqualTo: readerId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete(); // Delete each document that matches
    }
    //setState(() {}); // Refresh the UI after deletion
    return true; // Indicate success
  } catch (e) {
    print("Error deleting review: $e");
    return false; // Indicate failure
  }
}

void _showSuccessfulMessage(BuildContext context) {
  // Show the dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      // Create a unique key to identify the dialog
      final GlobalKey dialogKey = GlobalKey();

      // Automatically close the dialog after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (dialogKey.currentContext != null) {
          Navigator.of(dialogKey.currentContext!)
              .pop(); // Close the dialog if it's open
        }
      });

      return Dialog(
        key: dialogKey,
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
                'Review deleted Successfully!',
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
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('reader').doc(readerId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text("User data not found"));
        }

        Map<String, dynamic> userData =
            snapshot.data!.data() as Map<String, dynamic>;
        String username = userData['name'] ?? 'Anonymous';
        String profilePic = userData['profilePhoto'] ?? '';

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
                    // Use FutureBuilder to fetch the profile picture
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('reader')
                          .doc(readerId)
                          .get(),
                      builder: (context, memberSnapshot) {
                        if (memberSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox
                              .shrink(); // Don't display until data is ready
                        }

                        if (!memberSnapshot.hasData ||
                            !memberSnapshot.data!.exists) {
                          return CircleAvatar(
                            backgroundImage: const AssetImage(
                                'assets/images/profile_pic.png'),
                            radius: 18,
                          ); // Fallback to default if no data found
                        }

                        final memberData = memberSnapshot.data!.data()
                            as Map<String, dynamic>?;
                        if (memberData == null) {
                          return CircleAvatar(
                            backgroundImage: const AssetImage(
                                'assets/images/profile_pic.png'),
                            radius: 18,
                          ); // Fallback to default if memberData is null
                        }

                        String memberProfilePhoto =
                            memberData['profilePhoto'] ?? '';

                        return CircleAvatar(
                          backgroundImage: (memberProfilePhoto.isNotEmpty &&
                                  memberProfilePhoto.startsWith('http'))
                              ? NetworkImage(memberProfilePhoto)
                              : const AssetImage(
                                      'assets/images/profile_pic.png')
                                  as ImageProvider,
                          radius: 18,
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(
                                  width: 5), // Space between name and time
                              Text(
                                timeAgo(createdAt), // Call the timeAgo method
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
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
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        if (isOwner)
                          IconButton(
                            icon: Icon(Icons.delete,
                                color:
                                    const Color.fromARGB(255, 245, 114, 105)),
                            onPressed: () => _confirmDeleteReview(context),
                          ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailsPage(
                                  bookId: bookID,
                                  userId: readerId,
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
            ));
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
  bool isLoading = true; // Add a loading flag

  @override
  void initState() {
    super.initState();
    _fetchBookDetails();
  }

  // Fetch book details
  void _fetchBookDetails() async {
    try {
      var response = await http.get(Uri.parse(
          'https://www.googleapis.com/books/v1/volumes/${widget.bookID}'));

      if (response.statusCode == 200) {
        if (mounted) {
          // Check if the widget is still mounted
          setState(() {
            bookDetails = json.decode(response.body);
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            bookDetails = null;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          bookDetails = null;
          isLoading = false;
        });
      }
      print('Exception occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl =
        bookDetails?['volumeInfo']['imageLinks']['thumbnail'] ?? '';
    String title = bookDetails?['volumeInfo']['title'] ?? 'Unknown Title';

    return Container(
      width: 40, // Set a fixed width for the book cover
      height: 60, // Set a fixed height for the book cover
      child: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator while fetching
          : imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
    );
  }
}
