import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:folio/screens/OtherProfile/otherbookcardc.dart'; // For the Book Card UI
import 'package:folio/screens/Profile/book.dart'; // Book model
import 'package:folio/screens/book_details_page.dart'; // Book details page
import 'dart:convert';
import 'package:http/http.dart' as http;

class OtherProfileCurrentlyReadingPage extends StatefulWidget {
  final String memberId;
  final String username;

  const OtherProfileCurrentlyReadingPage({
    Key? key,
    required this.memberId,
    required this.username,
  }) : super(key: key);

  @override
  _OtherProfileCurrentlyReadingPageState createState() =>
      _OtherProfileCurrentlyReadingPageState();
}

class _OtherProfileCurrentlyReadingPageState
    extends State<OtherProfileCurrentlyReadingPage> {
  List<Book> currentlyReadingBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentlyReadingBooks();
  }

  // Fetch book details from Google Books API
  Future<Book> fetchBookFromGoogleAPI(String bookId) async {
    String url = 'https://www.googleapis.com/books/v1/volumes/$bookId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return Book.fromGoogleBooksAPI(data);
    } else {
      throw Exception('Failed to load book data from Google Books API');
    }
  }

  // Fetch Currently Reading Books
  Future<void> _fetchCurrentlyReadingBooks() async {
    final memberId = widget.memberId;

    try {
      CollectionReference currentlyRef = FirebaseFirestore.instance
          .collection('reader')
          .doc(memberId)
          .collection('currently reading');
      QuerySnapshot currentlySnapshot = await currentlyRef.orderBy('timestamp', descending: true) // Sorting line added here
        .get();

      List<Book> books = [];
      for (var doc in currentlySnapshot.docs) {
        var bookId = doc['bookID']; // Assuming Firestore stores bookID
        Book book =
            await fetchBookFromGoogleAPI(bookId); // Fetch from Google Books API
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3), // Set the background color
      appBar: AppBar(
        backgroundColor:
            Colors.transparent, // Set the AppBar background to transparent
        elevation: 0, // Remove shadow
        centerTitle: true,
        title: Text(
          '${widget.username} Currently Reading Books',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF351F1F), // Set the title color
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator while fetching
          : currentlyReadingBooks.isEmpty
              ? const Center(
                  child: Text(
                    'No books in currently reading list.',
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
                    return ReadOnlyCurrentlyReadingBookCard(book: book);
                  },
                ),
    );
  }
}
