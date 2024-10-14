import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_cardf.dart'; // Ensure this matches your filename for FinishedBooksCard
import 'book.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FinishedBooksPage extends StatefulWidget {
  final String userId;

  const FinishedBooksPage({super.key, required this.userId});

  @override
  _FinishedBooksPageState createState() => _FinishedBooksPageState();
}

class _FinishedBooksPageState extends State<FinishedBooksPage> {
  List<Book> finishedBooks = [];
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
        fetchFinishedBooks();
      });
    }
  }

  Future<void> fetchFinishedBooks() async {
    if (userId == null) return;

    try {
      CollectionReference booksRef = FirebaseFirestore.instance
          .collection('reader')
          .doc(userId)
          .collection('finished'); // Ensure collection name is 'finished'

      QuerySnapshot querySnapshot = await booksRef.get();

      List<Book> books = [];
      for (var doc in querySnapshot.docs) {
        var bookId = doc['bookID'];
        Book book = await fetchBookFromGoogleAPI(bookId);
        books.add(book);
      }

      setState(() {
        finishedBooks = books;
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching finished books: $error');
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

  void _onMenuSelected(String option, Book book) {
    print('Selected option: $option for book: ${book.title}');
    if (option == 'Move to Saved') {
      _moveBook(book, 'finished', 'save');
    } else if (option == 'Move to Currently Reading') {
      _moveBook(book, 'finished', 'currently reading');
    } else if (option == 'Remove from Finished') {
      _removeBook(book); // هنا نركز على عملية الحذف
    }
  }

  Future<void> _moveBook(
      Book book, String fromCollection, String toCollection) async {
    try {
      if (toCollection == 'finished' && fromCollection != 'finished') {
        await _incrementBooksRead();
      }

      if (fromCollection == 'finished' && toCollection != 'finished') {
        await _decrementBooksRead(); // عند النقل، يجب تقليل العدد في حال كان الكتاب منتهيا
      }

      // حذف الكتاب من المجموعة الحالية
      await FirebaseFirestore.instance
          .collection('reader')
          .doc(userId)
          .collection(fromCollection)
          .doc(book.id)
          .delete();

      // إضافة الكتاب إلى المجموعة الجديدة
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
        finishedBooks.remove(book);
      });
      print('Book moved to $toCollection successfully');
    } catch (e) {
      print('Error moving book: $e');
    }
  }

  Future<void> _removeBook(Book book) async {
    try {
      print('Removing book: ${book.title}');

      // هنا سيتم تقليل عدد الكتب المقروءة قبل إزالة الكتاب
      await _decrementBooksRead();

      await FirebaseFirestore.instance
          .collection('reader')
          .doc(userId)
          .collection('finished')
          .doc(book.id)
          .delete();

      setState(() {
        finishedBooks.remove(book);
      });
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
      appBar: AppBar(
        title: const Text('Finished Books'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : finishedBooks.isEmpty
              ? const Center(
                  child: Text(
                    'No books in your finished list.',
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
                  itemCount: finishedBooks.length,
                  itemBuilder: (context, index) {
                    Book book = finishedBooks[index];
                    return FinishedBookCard(
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