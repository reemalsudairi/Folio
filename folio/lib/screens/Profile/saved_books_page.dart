import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_cards.dart'; // Ensure this matches your filename for SavedBooks
import 'book.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SavedBooksPage extends StatefulWidget {
  final String userId;

  const SavedBooksPage({super.key, required this.userId});

  @override
  _SavedBooksPageState createState() => _SavedBooksPageState();
}

class _SavedBooksPageState extends State<SavedBooksPage> {
  List<Book> savedBooks = [];
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
        fetchSavedBooks();
      });
    }
  }

  Future<void> fetchSavedBooks() async {
    if (userId == null) return;

    try {
      CollectionReference booksRef = FirebaseFirestore.instance
          .collection('reader')
          .doc(userId)
          .collection('save'); // Ensure collection name is 'save'

      QuerySnapshot querySnapshot = await booksRef.get();

      List<Book> books = [];
      for (var doc in querySnapshot.docs) {
        var bookId = doc['bookID'];
        Book book = await fetchBookFromGoogleAPI(bookId);
        books.add(book);
      }

      setState(() {
        savedBooks = books;
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching saved books: $error');
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

  void _showConfirmationMessage(String bookTitle, String action) {
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

    Future.delayed(const Duration(seconds: 2), () {
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
                Icons
                    .warning, // Change icon to warning for removal confirmation
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to remove $bookTitle from the Saved list?',
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
                      backgroundColor: const Color.fromARGB(
                          255, 245, 114, 105), // Red for remove
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
                      backgroundColor: const Color.fromARGB(
                          255, 160, 160, 160), // Grey for "No" button
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

  void _onMenuSelected(String option, Book book) {
    switch (option) {
      case 'Move to Currently Reading':
        _moveBook(book, 'save', 'currently reading');
        break;
      case 'Move to Finished':
        _moveBook(book, 'save', 'finished');
        break;
      case 'Remove from Saved':
        _showRemoveBookConfirmation(
            book.title, book); // Show confirmation before removal
        break;
    }
  }

  Future<void> _moveBook(
      Book book, String fromCollection, String toCollection) async {
    try {
      if (toCollection == 'finished' && fromCollection != 'finished') {
        await _incrementBooksRead();
      }
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

      setState(() {
        savedBooks.remove(book);
      });
            _showConfirmationMessage(book.title,'Moved to $toCollection');

      print('Book moved to $toCollection successfully');
    } catch (e) {
      print('Error moving book: $e');
    }
  }

  Future<void> _removeBook(Book book) async {
    try {
      print('Removing book: ${book.title}');
      await FirebaseFirestore.instance
          .collection('reader')
          .doc(userId)
          .collection('save')
          .doc(book.id)
          .delete();

      setState(() {
        savedBooks.remove(book);
      });
            _showConfirmationMessage(book.title,'Removed from Saved');

      
      print('Book removed successfully');
    } catch (e) {
      print('Error removing book: $e');
    }
  }

  // Increment books read when a book is moved to "Finished"
  Future<void> _incrementBooksRead() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('reader')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        int booksRead = data?['booksRead'] ?? 0;

        await FirebaseFirestore.instance
            .collection('reader')
            .doc(userId)
            .update({'booksRead': booksRead + 1});

        print('Books read incremented');
      } else {
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

  // Decrement books read when a book is removed from "Finished"
  Future<void> _decrementBooksRead() async {
    try {
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

          print('Books read decremented');
        } else {
          print('Cannot decrement, booksRead is already zero');
        }
      }
    } catch (e) {
      print('Error decrementing books read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F8F3), // Set the background color to match
      appBar: AppBar(
        backgroundColor:
            Colors.transparent, // Set the AppBar background to transparent
        elevation: 0, // Remove shadow
        centerTitle: true,
        title: const Text(
          'Saved Books',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Color(0xFF351F1F), // Set the title color to match
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : savedBooks.isEmpty
              ? const Center(
                  child: Text(
                    'No books in your saved list.',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey), // Text style for no books message
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
                  itemCount: savedBooks.length,
                  itemBuilder: (context, index) {
                    Book book = savedBooks[index];
                    return SavedBookCard(
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
