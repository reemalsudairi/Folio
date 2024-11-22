import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'AdminLoginPage.dart';

class AdminDashboard extends StatefulWidget {
 final String adminUsername;

 const AdminDashboard({Key? key, required this.adminUsername}) : super(key: key);

 @override
 _AdminDashboardState createState() => _AdminDashboardState();
 
}

class _AdminDashboardState extends State<AdminDashboard> {
 final Set<String> _deletedReviews = {}; // Track deleted review IDs
 void _showLogoutConfirmationDialog() {
   showDialog(
     context: context,
     barrierDismissible: false,
     builder: (context) => Dialog(
       backgroundColor: Colors.transparent,
       child: Container(
         width: 300,
         padding: const EdgeInsets.all(20),
         decoration: BoxDecoration(
           color: const Color(0xFFF790AD).withOpacity(0.9),
           borderRadius: BorderRadius.circular(30),
         ),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Icon(
               Icons.exit_to_app,
               color: Colors.white,
               size: 40,
             ),
             const SizedBox(height: 10),
             Text(
               'Are you sure you want to log out?',
               style: const TextStyle(
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
                     _logout();
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.green,
                     minimumSize: const Size(100, 40),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(30.0),
                     ),
                   ),
                   child: const Text(
                     'Yes',
                     style: TextStyle(
                       color: Colors.white,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ),
                 ElevatedButton(
                   onPressed: () {
                     Navigator.of(context).pop();
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.grey,
                     minimumSize: const Size(100, 40),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(30.0),
                     ),
                   ),
                   child: const Text(
                     'Cancel',
                     style: TextStyle(
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

 Widget _buildConfirmationDialog({
  required String title,
  required String content,
  required VoidCallback onConfirm,
}) {
  return Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF790AD).withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
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
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(100, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  'Yes',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  minimumSize: const Size(100, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

 Future<void> _logout() async {
   await FirebaseAuth.instance.signOut();
   Navigator.pushAndRemoveUntil(
     context,
     MaterialPageRoute(builder: (context) => AdminLoginPage()),
     (route) => false,
   );
 }

Future<Book> fetchBookDetails(String bookId) async {
  final response = await http.get(Uri.parse('https://www.googleapis.com/books/v1/volumes/$bookId'));

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    return Book.fromGoogleBooksAPI(data);
  } else {
    throw Exception('Failed to load book');
  }
}

// Usage
Future<String> getBookThumbnail(String bookId) async {
  try {
    Book book = await fetchBookDetails(bookId);
    return book.thumbnailUrl; // Return the thumbnail URL
  } catch (e) {
    print('Error fetching book details: $e');
    return 'https://via.placeholder.com/150'; // Default placeholder URL
  }
}

Future<String> getWriterName(String reviewID) async {
  try {
    // Fetch the review document using the reviewId
    var reviewDoc = await FirebaseFirestore.instance.collection('reviews').doc(reviewID).get();
    if (!reviewDoc.exists) {
      return 'Unknown Writer'; // Handle case where review does not exist
    }

    // Get the readerId from the review document
    String readerId = reviewDoc.data()?['reader_id'];

    // Fetch the reader document using the readerId
    var readerDoc = await FirebaseFirestore.instance.collection('readers').doc(readerId).get();
    if (!readerDoc.exists) {
      return 'Unknown Writer'; // Handle case where reader does not exist
    }

    // Return the name from the reader document
    return readerDoc.data()?['name'] ?? 'Unknown Writer';
  } catch (e) {
    print('Error fetching writer name: $e');
    return 'Unknown Writer'; // Default name in case of error
  }
}


Future<String> getBookTitle(String bookId) async {
  try {
    Book book = await fetchBookDetails(bookId);
    return book.title; // Return the book title
  } catch (e) {
    print('Error fetching book details: $e');
    return 'Unknown Title'; // Default title
  }
}

 Stream<List<Map<String, dynamic>>> _fetchReportsWithReviewText() async* {
 try {
   final reportsCollection = FirebaseFirestore.instance.collection('reports');
   final reviewsCollection = FirebaseFirestore.instance.collection('reviews');
   final readerCollection = FirebaseFirestore.instance.collection('reader'); // Add this line

   // Fetch all reports from Firestore
   final reportsSnapshot = await reportsCollection.orderBy('timestamp', descending: true).get();

   List<Map<String, dynamic>> reportsWithReviewText = [];

   for (var report in reportsSnapshot.docs) {
     try {
       // Extract reviewId safely
       final reportData = report.data() as Map<String, dynamic>;
       final reviewId = reportData['reviewId'];
       final userId = reportData['userId'];

       if (reviewId == null || reviewId.isEmpty) {
         print('Skipped report with missing reviewId: ${report.id}');
         continue; // Skip if reviewId is invalid
       }

       // Fetch review document
       final reviewSnapshot = await reviewsCollection.doc(reviewId).get();
        final userSnapshot = await readerCollection.doc(userId).get(); // Fetch user data

         String username = 'Unknown User'; // Default username
         if (userSnapshot.exists) {
         final userData = userSnapshot.data() as Map<String, dynamic>;
         username = userData['username'] ?? 'Unknown User'; // Get username
       }

       if (reviewSnapshot.exists) {
         final reviewData = reviewSnapshot.data() as Map<String, dynamic>;
         final reviewText = reviewData['reviewText'] ?? 'Review text missing';

         // Add the data to the list with correct casting
         reportsWithReviewText.add({
           'bookId': reportData['bookId'],
           'userId': userId,
           'timestamp': reportData['timestamp'],
           'reasons': List<String>.from(reportData['reasons'] ?? []), // Ensuring reasons is a list of Strings
           'reviewText': reviewText,
           'reviewId': reviewId,
            'username': username, // Add username here
         });
       } else {
         print('Review not found for reviewId: $reviewId');
       }
     } catch (e) {
       print('Error processing report ${report.id}: $e');
     }
   }

   print('Total reports processed: ${reportsWithReviewText.length}');
   yield reportsWithReviewText;
 } catch (e) {
   print('Error fetching reports: $e');
   yield [];
 }
}


 @override
 Widget build(BuildContext context) {
   return Scaffold(
     body: SafeArea(
       child: Padding(
         padding: const EdgeInsets.all(0.0),
         child: Column(
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Padding(
                   padding: const EdgeInsets.only(left: 20.0),
                   child: Text(
                     'Hello, Admin ${widget.adminUsername}!',
                     style: TextStyle(
                       fontSize: 20,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ),
                 Container(
                   height: 90,
                   width: 170,
                   child: ClipRect(
                     child: Align(
                       alignment: Alignment.center,
                       heightFactor: 0.5,
                       child: Image.asset(
                         'assets/images/Logo.png',
                         width: 170,
                         fit: BoxFit.cover,
                       ),
                     ),
                   ),
                 ),
                 Padding(
                   padding: const EdgeInsets.only(right: 20.0),
                   child: ElevatedButton(
                     onPressed: () => _showLogoutConfirmationDialog(),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.red,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8.0),
                       ),
                     ),
                     child: Text(
                       'Logout',
                       style: TextStyle(color: Colors.white),
                     ),
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 10),
             Expanded(
               child: StreamBuilder<List<Map<String, dynamic>>>(
                 stream: _fetchReportsWithReviewText(),
                 builder: (context, snapshot) {
                   if (snapshot.connectionState == ConnectionState.waiting) {
                     return Center(child: CircularProgressIndicator());
                   }
                   if (snapshot.hasError) {
                     return Center(child: Text('Error loading reports'));
                   }
                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
                     return Center(child: Text('No reports found'));
                   }

                   final reports = snapshot.data!;

                   return ListView.builder(
 itemCount: reports.length,
 itemBuilder: (context, index) {
   final report = reports[index];
   final reasons = List<String>.from(report['reasons'] ?? []);
   final reviewId = report['reviewId']; // Assuming you have the reviewId to delete the review
   


   
  

   // Function to delete the review from Firestore
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
       child: const Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           Icon(
             Icons.check,
             color: Colors.white,
             size: 40,
           ),
           SizedBox(height: 10),
           Text(
             'Successfully Deleted Review!',
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

 // Close the dialog after 4 seconds
 Future.delayed(const Duration(seconds: 2), () {
   Navigator.of(context).pop();
 });
}



// Method to delete the review from Firestore
Future<void> _deleteReview(String reviewId) async {
   try {
     if (reviewId.isEmpty) {
       print("Review ID is invalid or empty.");
       return;
     }

     // Check if the review document exists before trying to delete
     final reviewDoc = await FirebaseFirestore.instance.collection('reviews').doc(reviewId).get();

     if (reviewDoc.exists) {
       await FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();
       _showConfirmationMessage();
     } else {
       print("Review document does not exist.");
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text('Review not found!'),
       ));
     }
   } catch (e) {
     print("Error deleting review: $e");
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
       content: Text('Error deleting review: $e'),
     ));
   }
 }

 void _showDeleteConfirmationDialog(String reviewId) {
   showDialog(
     context: context,
     barrierDismissible: false,
     builder: (context) => Dialog(
       backgroundColor: Colors.transparent,
       child: Container(
         width: 300,
         padding: const EdgeInsets.all(20),
         decoration: BoxDecoration(
           color: const Color(0xFFF790AD).withOpacity(0.9),
           borderRadius: BorderRadius.circular(30),
         ),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Icon(
               Icons.delete_forever,
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
               mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
                 ElevatedButton(
                   onPressed: () {
                     Navigator.of(context).pop();
                     _deleteReview(reviewId); // Pass reviewId to the delete function
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.red,
                     minimumSize: const Size(100, 40),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(30.0),
                     ),
                   ),
                   child: const Text(
                     'Yes',
                     style: TextStyle(
                       color: Colors.white,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ),
                 ElevatedButton(
                   onPressed: () {
                     Navigator.of(context).pop();
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.grey,
                     minimumSize: const Size(100, 40),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(30.0),
                     ),
                   ),
                   child: const Text(
                     'Cancel',
                     style: TextStyle(
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


   return Card(
     margin: const EdgeInsets.all(10),
     shape: RoundedRectangleBorder(
       borderRadius: BorderRadius.circular(12), // Optional: Adds rounded corners
     ),
     elevation: 4, // Optional: Adds a shadow for better visibility
     color: Colors.white, // Set the background color to white
     child: Padding(
       padding: const EdgeInsets.all(10.0),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
        children: [
  // Row for "Reported by" and "Reported On"
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space them out
    children: [
      // Reported by text
      Text(
        'Reported by: ${report['username']}',
        style: TextStyle(fontSize: 12, color: Colors.grey), // Smaller and gray
      ),
      
      // Reported On text
      Text(
        'Reported On: ${report['timestamp'].toDate()}',
        style: TextStyle(fontSize: 12, color: Colors.grey), // Smaller and gray
      ),
    ],
  ),

  // Fetch and display the writer's name
  FutureBuilder<String>(
    future: getWriterName(reviewId), // Fetch writer's name using reviewId
    builder: (context, writerSnapshot) {
      if (writerSnapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator(); // Show loading indicator
      }
      if (writerSnapshot.hasError) {
        return Text('Error: ${writerSnapshot.error}');
      }

      final writerName = writerSnapshot.data ?? 'Unknown Writer';

      return Text(
        'Written by: $writerName',
        style: TextStyle(fontWeight: FontWeight.bold), // Bold style for the writer's name
      );
    },
  ),

  // Fetch and display book title and thumbnail
  FutureBuilder<String>(
    future: getBookTitle(report['bookId']), // Fetch book title using bookId
    builder: (context, titleSnapshot) {
      if (titleSnapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator(); // Show loading indicator
      }
      if (titleSnapshot.hasError) {
        return Text('Error: ${titleSnapshot.error}');
      }

      final bookTitle = titleSnapshot.data ?? 'Unknown Title';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display book title
          Text(
            'Book name: $bookTitle',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          
          // Fetch and display book thumbnail
          FutureBuilder<String>(
            future: getBookThumbnail(report['bookId']), // Fetch book thumbnail
            builder: (context, thumbnailSnapshot) {
              if (thumbnailSnapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(); // Show loading indicator
              }
              if (thumbnailSnapshot.hasError) {
                return Text('Error: ${thumbnailSnapshot.error}');
              }

              final bookThumbnail = thumbnailSnapshot.data ?? 'https://via.placeholder.com/150';

              return Column(
                children: [
                  // Display book cover
                  Image.network(bookThumbnail, height: 100), // Display book thumbnail
                  SizedBox(height: 8), // Add some space
                ],
              );
            },
          ),
        ],
      );
    },
  ),

  // Review text
  Text('Review Text: ${report['reviewText']}'),

  // Reasons section
  Text('Reasons:', style: TextStyle(fontWeight: FontWeight.bold)),
  ...reasons.map((reason) => Text('- $reason')).toList(),

  const SizedBox(height: 10),

  // Delete button
  Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      ElevatedButton(
        onPressed: () {
          _showDeleteConfirmationDialog(reviewId); // Pass reviewId to the dialog 
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red, // Red color for the delete button
          minimumSize: const Size(100, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: const Text(
          'Delete Review',
          style: TextStyle(color: Colors.white),
        ),
      ),
    ],
  ),
],
       ),
     ),
   );
                           
 },
);

                 },
               ),
             ),
           ],
         ),
       ),
     ),
   );
 }
}

class Book {
 final String id; // Unique ID for the book (from Google Books API)
 final String title; // Title of the book
 final String author; // Author(s) of the book
 final String thumbnailUrl; // URL for the book's thumbnail (image)
 final String description; // Description of the book (optional)
 final String publishedDate; // Published date of the book (optional)
 final int pageCount; // Number of pages in the book (optional)

 // Constructor to initialize the Book object
 Book({
   required this.id,
   required this.title,
   required this.author,
   required this.thumbnailUrl,
   this.description = '',
   this.publishedDate = '',
   this.pageCount = 0,
 });

 // Factory constructor to create a Book object from Google Books API data
 factory Book.fromGoogleBooksAPI(Map<String, dynamic> data) {
   var volumeInfo = data['volumeInfo'];
   return Book(
     id: data['id'] ?? 'Unknown ID',
     title: volumeInfo['title'] ?? 'No title available',
     author: (volumeInfo['authors'] != null && volumeInfo['authors'].isNotEmpty)
         ? volumeInfo['authors'].join(', ')
         : 'Unknown Author',
     thumbnailUrl: volumeInfo['imageLinks']?['thumbnail'] ??
         'https://via.placeholder.com/150', // Placeholder if thumbnail is missing
     description: volumeInfo['description'] ?? 'No description available',
     publishedDate: volumeInfo['publishedDate'] ?? 'Unknown date',
     pageCount: volumeInfo['pageCount'] ?? 0,
   );
 }
}
