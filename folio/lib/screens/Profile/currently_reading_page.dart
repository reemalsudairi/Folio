import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_cardc.dart'; // Ensure this matches your filename for CurrentlyReadingBookCard
import 'book.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrentlyReadingPage extends StatefulWidget {
  final String userId;

  const CurrentlyReadingPage({super.key, required this.userId});

  @override
  _CurrentlyReadingPageState createState() => _CurrentlyReadingPageState();
}

class _CurrentlyReadingPageState extends State<CurrentlyReadingPage> {
  List<Book> currentlyReadingBooks = [];
  String? userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        userId = user.uid;
        fetchCurrentlyReadingBooks();
      });
    }
  }

  Future<void> fetchCurrentlyReadingBooks() async {
    if (userId == null) return;

    try {
      CollectionReference booksRef = FirebaseFirestore.instance
          .collection('reader')
          .doc(userId)
          .collection('currently reading');

      QuerySnapshot querySnapshot = await booksRef.orderBy('timestamp', descending: true) // Sorting line added here
        .get();

      List<Book> books = [];
      for (var doc in querySnapshot.docs) {
        var bookId = doc['bookID'];
        Book book = await fetchBookFromGoogleAPI(bookId);
        books.add(book);
      }

      setState(() {
        currentlyReadingBooks = books;
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching currently reading books: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Book> fetchBookFromGoogleAPI(String bookId) async {
    String url = 'https://www.googleapis.com/books/v1/volumes/$bookId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return Book.fromGoogleBooksAPI(data);
    } else {
      throw Exception('Failed to load book data');
    }
  }

  void _showConfirmationMessage(String bookTitle,String action) {
    String formattedAction = action[0].toUpperCase() + action.substring(1);
    showDialog(
      context: context,
      barrierDismissible: false,
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
                ' $bookTitle $formattedAction list successfully!',
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

    Future.delayed(const Duration(seconds: 1), () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }
  void _showRemoveBookConfirmation(String bookTitle, Book book) {
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
              Icons.warning, // Change icon to warning for removal confirmation
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to remove $bookTitle from the Currently Reading list?',
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
                    backgroundColor: const Color.fromARGB(255, 245, 114, 105), // Red for remove
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: const Size(100, 40),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _removeBook(book); // Proceed to remove the book
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
                    backgroundColor: const Color.fromARGB(255, 160, 160, 160), // Grey for "No" button
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

void _onMenuSelected(String option, Book book) {
  switch (option) {
    case 'Move to Saved':
      _moveBook(book, 'currently reading', 'save');
      break;
    case 'Move to Finished':
      _moveBook(book, 'currently reading', 'finished');
      break;
    case 'Remove from Currently Reading':
      _showRemoveBookConfirmation(book.title,book); // Show confirmation before removal
      break;
  }
}



  Future<void> _moveBook(Book book, String fromCollection, String toCollection) async {
    try {
      if (fromCollection == 'finished' && toCollection != 'finished') {
        await _decrementBooksRead(); 
      }

      await FirebaseFirestore.instance
          .collection('reader')
          .doc(userId)
          .collection(fromCollection)
          .doc(book.id)
          .delete();

      await FirebaseFirestore.instance
          .collection('reader')
          .doc(userId)
          .collection(toCollection)
          .doc(book.id)
          .set({
        'bookID': book.id,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (toCollection == 'finished' && fromCollection != 'finished') {
        await _incrementBooksRead();
      }

      setState(() {
        currentlyReadingBooks.remove(book);
      });

      _showConfirmationMessage(book.title,'Moved to $toCollection');
    } catch (e) {
      print('Error moving book: $e');
    }
  }

  Future<void> _removeBook(Book book) async {
    try {
      await FirebaseFirestore.instance
          .collection('reader')
          .doc(userId)
          .collection('currently reading')
          .doc(book.id)
          .delete();

      setState(() {
        currentlyReadingBooks.remove(book);
      });

      _showConfirmationMessage(book.title,'Removed from Currently Reading');
    } catch (e) {
      print('Error removing book: $e');
    }
  }

Future<void> _incrementBooksRead() async {
  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('reader')
        .doc(userId)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
      int booksRead = data?['booksRead'] ?? 0;
      int booksGoal = data?['books'] ?? 0;
      bool goalAchievedOnce = data?['goalAchievedOnce'] ?? false; // Flag to check if message was shown

      // Increment the booksRead field
      booksRead++;
      print('Books read incremented to: $booksRead');

      await FirebaseFirestore.instance
          .collection('reader')
          .doc(userId)
          .update({'booksRead': booksRead});

      // Check if the yearly goal is met and the message has not been shown yet
      if (booksRead >= booksGoal && !goalAchievedOnce) {
        print('Goal reached for the first time!');
        _showGoalAchievedDialog();  // Show the goal achieved dialog

        // Update the flag so the message doesn't appear again for this goal
        await FirebaseFirestore.instance
            .collection('reader')
            .doc(userId)
            .update({'goalAchievedOnce': true});
      }
    } else {
      // Initialize the booksRead field if it doesn't exist
      await FirebaseFirestore.instance
          .collection('reader')
          .doc(userId)
          .update({'booksRead': 1});
      print('Books read initialized and incremented');
    }
  } catch (e) {
    print('Error incrementing books read: $e');
  }
}

void _showGoalAchievedDialog() {
  if (!mounted) return; // Ensure the widget is still mounted

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              color: Color(0xFFF790AD),// Icon color matching the progress bar
              size: 50,
            ),
            const SizedBox(width: 10),
            Text(
              'Goal Achieved!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],  // Matching design colors
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Congratulations, you have reached your yearly reading goal!',
              style: TextStyle(
                color: Colors.brown[600],  // Keeping a consistent color palette
                fontWeight: FontWeight.bold,
                  fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: 1,  // Full progress to signify the goal is met
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Color(0xFFF790AD)),
              minHeight: 13,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
          ],
        ),
      );
    },
  );

  // Automatically close the dialog after 5 seconds
  Future.delayed(const Duration(seconds: 3), () {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  });
}

  Future<void> _decrementBooksRead() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('reader')
        .doc(userId)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
      int booksRead = data?['booksRead'] ?? 0;

      if (booksRead > 0) {
        await FirebaseFirestore.instance
            .collection('reader')
            .doc(userId)
            .update({'booksRead': booksRead - 1});
      }
    }
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF8F8F3), // Set the background color
    appBar: AppBar(
      backgroundColor: Colors.transparent, // Set the AppBar background to transparent
      elevation: 0, // Remove shadow
      centerTitle: true,
      title: const Text(
        'Currently Reading Books',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 26,
          color: Color(0xFF351F1F), // Set the title color
        ),
      ),
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : currentlyReadingBooks.isEmpty
            ? const Center(
                child: Text(
                  'No books in your currently reading list.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.66,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: currentlyReadingBooks.length,
                itemBuilder: (context, index) {
                  Book book = currentlyReadingBooks[index];
                  return CurrentlyReadingBookCard(
                    book: book,
                    userId: userId!,
                    onMenuSelected: (String option) {
                      _onMenuSelected(option, book);
                    },
                  );
                },
              ),
  );
}
}
