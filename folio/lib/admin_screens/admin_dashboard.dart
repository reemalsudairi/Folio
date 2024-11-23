import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/Profile/book.dart';
import 'package:http/http.dart' as http;

import 'AdminLoginPage.dart';

class AdminDashboard extends StatefulWidget {
final String adminUsername;

const AdminDashboard({Key? key, required this.adminUsername}) : super(key: key);

@override
_AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
// Track deleted review IDs
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

Future<Book> fetchBookDetails(String bookID) async {
  final response = await http.get(Uri.parse('https://www.googleapis.com/books/v1/volumes/$bookID'));

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    // Log the entire response for debugging
    print('Fetched book details: $data');
    return Book.fromGoogleBooksAPI(data);
  } else {
    print('Failed to load book details for bookId $bookID, statusCode: ${response.statusCode}');
    throw Exception('Failed to load book');
  }
}


Future<String> getBookThumbnail(String bookID) async {
try {
  Book book = await fetchBookDetails(bookID);
  return book.thumbnailUrl ?? 'https://via.placeholder.com/150'; // Return a default if null
} catch (e) {
  print('Error fetching book details: $e');
  return 'https://via.placeholder.com/150'; // Default placeholder URL in case of error
}
}






Future<String> getBookTitle(String bookID) async {
  if (bookID.isEmpty) {
    print('Warning: bookId is empty. Cannot fetch book title.');
    return 'Unknown Title';
  }

  try {
    Book book = await fetchBookDetails(bookID);
    print('Fetched book title: ${book.title}'); // Log the fetched title
    return book.title ?? 'Unknown Title'; // Return title or default
  } catch (e) {
    print('Error fetching book details for bookId $bookID: $e');
    return 'Unknown Title'; // Return default title on error
  }
}


Stream<List<Map<String, dynamic>>> _fetchReportsWithReviewText() {
 final reportsCollection = FirebaseFirestore.instance.collection('reports');
 final reviewsCollection = FirebaseFirestore.instance.collection('reviews');
 final readerCollection = FirebaseFirestore.instance.collection('reader');

 return reportsCollection.orderBy('timestamp', descending: true).snapshots().asyncMap((reportsSnapshot) async {
   List<Map<String, dynamic>> reportsWithReviewText = [];

   for (var report in reportsSnapshot.docs) {
     try {
       final reportData = report.data() as Map<String, dynamic>;
       final reviewId = reportData['reviewId'] ?? '';
       final userId = reportData['WhoReportID'] ?? '';
       final reviewWriterId = reportData['reviewWriterID'] ?? '';

       if (reviewId.isEmpty) {
         continue; // Skip if reviewId is missing
       }

       // Fetch the review data
       final reviewSnapshot = await reviewsCollection.doc(reviewId).get();
       // Fetch the user data
       final userSnapshot = await readerCollection.doc(userId).get();
       // Fetch the review writer data
       final reviewWriterSnapshot = await readerCollection.doc(reviewWriterId).get();

       String username = 'Unknown Reader';
       String reviewWriterUsername = 'Unknown Reader';  // For the review writer

       if (userSnapshot.exists) {
         final userData = userSnapshot.data() as Map<String, dynamic>;
         username = userData['username'] ?? 'Unknown Reader';
       }

       if (reviewWriterSnapshot.exists) {
         final reviewWriterData = reviewWriterSnapshot.data() as Map<String, dynamic>;
         reviewWriterUsername = reviewWriterData['username'] ?? 'Unknown Reader'; // Fetch reader username
       }

       if (reviewSnapshot.exists) {
         final reviewData = reviewSnapshot.data() as Map<String, dynamic>;
         final reviewText = reviewData['reviewText'] ?? 'Review text missing';

         reportsWithReviewText.add({
           'bookID': reportData['bookID'] ?? '',
           'userId': userId,
           'timestamp': reportData['timestamp'],
           'reasons': List<String>.from(reportData['reasons'] ?? []),
           'reviewText': reviewText,
           'reviewId': reviewId,
           'username': username,
           'reviewWriterUsername': reviewWriterUsername,
           'reviewWriterId': reviewWriterId,
         });
       }
     } catch (e) {
       print('Error processing report ${report.id}: $e');
     }
   }

   return reportsWithReviewText;
 });
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
               final reviewId = report['reviewId']??'';
               if (reviewId.isEmpty) {
               print('Review ID is missing!');
                // Skip this report
                } // Assuming you have the reviewId to delete the review
               final reviewWriterUsername = report['reviewWriterUsername']??'';
               final reviewWriterId = report['reviewWriterId']??'';
               final bookID=report['bookID'] ?? '';

// Function to show confirmation message
void _showConfirmationMessage(String message) {
 showDialog(
   context: context,
   barrierDismissible: false, // Prevent dismissal by tapping outside
   builder: (context) {
     return AlertDialog(
       backgroundColor: Colors.transparent, // Transparent background
       content: Container(
         width: 300, // Outer container width
         height: 200, // Outer container height
         decoration: BoxDecoration(
           color: Colors.lightGreen.withOpacity(0.7), // Light green background with transparency
           borderRadius: BorderRadius.circular(30), // Rounded corners
         ),
         child: Stack(
           children: [
             // Center content
             Center(
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(
                     Icons.check_circle, // Checkmark icon
                     color: Colors.white,
                     size: 40, // Adjust size as needed
                   ),
                   const SizedBox(height: 10), // Space between icon and text
                   Text(
                     message,
                     style: const TextStyle(
                       color: Colors.white,
                       fontSize: 18, // Change text color to white
                     ),
                     textAlign: TextAlign.center,
                   ),
                 ],
               ),
             ),
             // 'X' button positioned inside the dialog
             Positioned(
               top: 8, // Padding from the top of the container
               right: 8, // Padding from the right of the container
               child: GestureDetector(
                 onTap: () {
                   Navigator.of(context).pop(); // Close the dialog
                 },
                 child: const Icon(
                   Icons.close, // 'X' icon
                   color: Colors.white, // White color for visibility
                   size: 30, // Icon size
                 ),
               ),
             ),
           ],
         ),
       ),
     );
   },
 );
}





// Method to delete the review from Firestore
// Method to delete the review and its associated report from Firestore
Future<void> _deleteReview(String reviewId, String reviewWriterId) async {
 try {
   // Validate reviewId and reviewWriterId
   if (reviewId.isEmpty || reviewWriterId.isEmpty) {
     print("Review ID or Writer ID is invalid or empty.");
     return;
   }

   // Check if the review document exists
   final reviewDoc = await FirebaseFirestore.instance.collection('reviews').doc(reviewId).get();
   if (!reviewDoc.exists) {
     print("Review not found for ID: $reviewId");
     return;
   }

   // Delete the review
   await FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();
   print("Review deleted successfully: $reviewId");

   // Now, delete the associated report
   final reportsCollection = FirebaseFirestore.instance.collection('reports');
   final reportQuery = await reportsCollection.where('reviewId', isEqualTo: reviewId).get();

   // Check if the report exists
   if (reportQuery.docs.isNotEmpty) {
     for (var report in reportQuery.docs) {
       await report.reference.delete();
       print("Report deleted successfully: ${report.id}");
     }
   } else {
     print("No report found for reviewId: $reviewId");
   }

   // Update the NumberOfReports for the review writer
   final readerDoc = await FirebaseFirestore.instance.collection('reader').doc(reviewWriterId).get();
   if (readerDoc.exists) {
     final readerData = readerDoc.data() as Map<String, dynamic>?;
     final currentReportsCount = readerData?['NumberOfReports'] ?? 0;
     final updatedReportsCount = currentReportsCount + 1;

     // Update the NumberOfReports and check if the reader should be banned
     await FirebaseFirestore.instance.collection('reader').doc(reviewWriterId).update({
       'NumberOfReports': updatedReportsCount,
       if (updatedReportsCount >= 3) 'banned': true,
     });

     print('Successfully updated NumberOfReports for reader: $reviewWriterId');
     if (updatedReportsCount >= 3) {
       print('Reader banned: $reviewWriterId');
     }
   } else {
     print('Reader not found for ID: $reviewWriterId');
   }

   // Show success confirmation dialog
   _showConfirmationMessage('Successfully deleted review');

   // Refresh the state to fetch updated reports
   setState(() {});
 } catch (e) {
   print('Error deleting review: $e');
 }
}

Future<void> _keepReview(String reviewId) async {
 try {
   // Fetch the report document that contains the reviewId
   final reportsCollection = FirebaseFirestore.instance.collection('reports');
   final reportQuery = await reportsCollection.where('reviewId', isEqualTo: reviewId).get();

   // Check if the report exists
   if (reportQuery.docs.isNotEmpty) {
     // Delete the report
     for (var report in reportQuery.docs) {
       await report.reference.delete();
       print("Report deleted successfully: ${report.id}");
     }
     // Optionally show a confirmation message
     _showConfirmationMessage('Successfully kept review');
   } else {
     print("No report found for reviewId: $reviewId");
   }

   // Refresh the state to fetch updated reports
   setState(() {});
 } catch (e) {
   print('Error keeping review: $e');
 }
}

void _showDeleteConfirmationDialog(String reviewId, String reviewWriterId) {
   print("showdeleteConfirmationMessage");
// Show a dialog with confirmation to delete the review
showDialog(
  context: context,
  barrierDismissible: false, // User cannot dismiss by tapping outside
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
                  // Check if reviewId and reviewWriterId are not null or empty before proceeding
                  if (reviewId.isNotEmpty && reviewWriterId.isNotEmpty) {
                    _deleteReview(reviewId, reviewWriterId);
                    Navigator.of(context).pop(); // Close the dialog after deletion
                  }
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
                  Navigator.of(context).pop(); // Close the dialog
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
void _showKeepConfirmationDialog(String reviewId) {
   print("showdeleteConfirmationMessage");
// Show a dialog with confirmation to delete the review
showDialog(
  context: context,
  barrierDismissible: false, // User cannot dismiss by tapping outside
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
            'Are you sure you want to keep this review?',
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
                  // Check if reviewId and reviewWriterId are not null or empty before proceeding
                  if (reviewId.isNotEmpty ) {
                    _keepReview(reviewId);
                    Navigator.of(context).pop(); // Close the dialog after deletion
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 65, 165, 26),
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
                  Navigator.of(context).pop(); // Close the dialog
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
        // Row for "Reported by"
        Row(
          mainAxisAlignment: MainAxisAlignment.start, // Align to start
          children: [
            Text(
              'Reported by:',
              style: TextStyle(fontSize: 12, color: Colors.brown), // Label in brown
            ),
            const SizedBox(width: 10), // Add some space between title and value
            Text(
              '${report['username']}',
              style: TextStyle(fontSize: 12, color: Color(0xFFF790AD)), // Value in specified color
            ),
          ],
        ),
        const SizedBox(height: 5), // Add some space between rows
        // Row for "Reported On"
        Row(
          mainAxisAlignment: MainAxisAlignment.start, // Align to start
          children: [
            Text(
              'Reported On:',
              style: TextStyle(fontSize: 12, color: Colors.brown), // Label in brown
            ),
            const SizedBox(width: 10), // Add some space between title and value
            Text(
              '${report['timestamp'].toDate()}',
              style: TextStyle(fontSize: 12, color: Color(0xFFF790AD)), // Value in specified color
            ),
          ],
        ),
        const SizedBox(height: 5), // Add some space between rows
        // Row for "Written By"
        Row(
          mainAxisAlignment: MainAxisAlignment.start, // Align to start
          children: [
            Text(
              'Written By:',
              style: TextStyle(fontSize: 12, color: Colors.brown), // Label in brown
            ),
            const SizedBox(width: 10), // Add some space between title and value
            Text(
              '$reviewWriterUsername',
              style: TextStyle(fontSize: 12, color: Color(0xFFF790AD)), // Value in specified color
            ),
          ],
        ),
        const SizedBox(height: 5), // Add some space between rows
        // FutureBuilder for "Book Name"
        FutureBuilder<String>(
          future: getBookTitle(report['bookID']),
          builder: (context, titleSnapshot) {
            if (titleSnapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(); // Show loading indicator
            }
            if (titleSnapshot.hasError) {
              return Text('Error: ${titleSnapshot.error}'); // Show error message
            }

            final bookTitle = titleSnapshot.data ?? 'Unknown Title';

            return Row(
              mainAxisAlignment: MainAxisAlignment.start, // Align to start
              children: [
                Text(
                  'Book name:',
                  style: TextStyle(fontSize: 12, color: Colors.brown), // Label in brown
                ),
                const SizedBox(width: 10), // Add some space between title and value
                Text(
                  '$bookTitle',
                  style: TextStyle(fontSize: 12, color: Color(0xFFF790AD)), // Value in specified color
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 5), // Add some space between rows
        // Row for "Review Text"
        Row(
          mainAxisAlignment: MainAxisAlignment.start, // Align to start
          children: [
            Text(
              'Review Text:',
              style: TextStyle(fontSize: 12, color: Colors.brown), // Label in brown
            ),
            const SizedBox(width: 10), // Add some space between title and value
            Expanded( // Use Expanded to allow the text to take available space
              child: Text(
                '${report['reviewText']}',
                style: TextStyle(fontSize: 12, color: Color(0xFFF790AD)), // Value in specified color
                overflow: TextOverflow.ellipsis, // Handle overflow
                maxLines: 1, // Limit to one line
              ),
            ),
          ],
        ),
        const SizedBox(height: 5), // Add some space between rows
        // Row for "Reasons"
        Row(
          mainAxisAlignment: MainAxisAlignment.start, // Align to start
          children: [
            Text(
              'Reasons:',
              style: TextStyle(fontSize: 12, color: Colors.brown), // Label in brown
            ),
          ],
        ),
        ...reasons.map((reason) => Row(
          mainAxisAlignment: MainAxisAlignment.start, // Align to start
          children: [
            Text(
              '- $reason',
              style: TextStyle(fontSize: 12, color: Color(0xFFF790AD)), // Value in specified color
            ),
          ],
        )).toList(),
        const SizedBox(height: 10),
        // Keep Review button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                if (reviewId != null) {
                  print("Keep button pressed for reviewId: $reviewId"); // Debugging line
                  _showKeepConfirmationDialog(reviewId);
                } else {
                  print("Error: reviewId is null.");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 150, 150, 150), shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Keep Review',
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
            ),
            SizedBox(width: 10), // Add some space between buttons
            ElevatedButton(
              onPressed: () {
                if (reviewId != null && reviewWriterId != null) {
                  print("Delete button pressed for reviewId: $reviewId"); // Debugging line
                  _showDeleteConfirmationDialog(reviewId!, reviewWriterId!);
                } else {
                  print("Error: reviewId or reviewWriterId is null.");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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