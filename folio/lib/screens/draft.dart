// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class CurrentlyReadingPage extends StatefulWidget {
//   const CurrentlyReadingPage({Key? key}) : super(key: key);

//   @override
//   _CurrentlyReadingPageState createState() => _CurrentlyReadingPageState();
// }

// class _CurrentlyReadingPageState extends State<CurrentlyReadingPage> {
//   final String userId = FirebaseAuth.instance.currentUser!.uid;
//   List<Book> currentlyReadingBooks = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchCurrentlyReadingBooks();
//   }

//   // Fetch the user's currently reading books from Firestore
//   Future<void> fetchCurrentlyReadingBooks() async {
//     try {
//       CollectionReference booksRef = FirebaseFirestore.instance
//           .collection('readers')
//           .doc(userId)
//           .collection('currentlyReading');

//       QuerySnapshot querySnapshot = await booksRef.get();
//       if (querySnapshot.docs.isEmpty) {
//         setState(() {
//           currentlyReadingBooks = [];
//         });
//       } else {
//         List<Book> books = [];
//         for (var doc in querySnapshot.docs) {
//           var bookId = doc['bookId'];
//           // Fetch book details from Google Books API
//           Book book = await fetchBookFromGoogleAPI(bookId);
//           books.add(book);
//         }
//         setState(() {
//           currentlyReadingBooks = books;
//         });
//       }
//     } catch (error) {
//       print('Error fetching books: $error');
//     }
//   }

//   // Fetch book details from Google Books API
//   Future<Book> fetchBookFromGoogleAPI(String bookId) async {
//     String url = 'https://www.googleapis.com/books/v1/volumes/$bookId';
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode == 200) {
//       var data = json.decode(response.body);
//       return Book.fromGoogleBooksAPI(data);
//     } else {
//       throw Exception('Failed to load book data');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Currently reading'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//         ),
//       ),
//       body: currentlyReadingBooks.isEmpty
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Image.asset(
//                     'assets/no_books.png', // Placeholder image when no books exist
//                     height: 150,
//                   ),
//                   const SizedBox(height: 20),
//                   const Text(
//                     'No books in your currently reading list.',
//                     style: TextStyle(fontSize: 18, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             )
//           : GridView.builder(
//               padding: const EdgeInsets.all(16.0),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 crossAxisSpacing: 16,
//                 mainAxisSpacing: 16,
//                 childAspectRatio: 0.65,
//               ),
//               itemCount: currentlyReadingBooks.length,
//               itemBuilder: (context, index) {
//                 Book book = currentlyReadingBooks[index];
//                 return BookCard(book: book);
//               },
//             ),
//     );
//   }
// }

// // Model for Book data
// class Book {
//   final String title;
//   final String author;
//   final String thumbnailUrl;

//   Book({required this.title, required this.author, required this.thumbnailUrl});

//   factory Book.fromGoogleBooksAPI(Map<String, dynamic> data) {
//     var volumeInfo = data['volumeInfo'];
//     return Book(
//       title: volumeInfo['title'] ?? 'Unknown Title',
//       author: (volumeInfo['authors'] != null)
//           ? volumeInfo['authors'].join(', ')
//           : 'Unknown Author',
//       thumbnailUrl: volumeInfo['imageLinks'] != null
//           ? volumeInfo['imageLinks']['thumbnail']
//           : '',
//     );
//   }
// }

// // BookCard Widget
// class BookCard extends StatelessWidget {
//   final Book book;

//   const BookCard({required this.book});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Image.network(
//           book.thumbnailUrl,
//           height: 150,
//           fit: BoxFit.cover,
//           errorBuilder: (context, error, stackTrace) => Container(
//             height: 150,
//             color: Colors.grey[300],
//             child: const Icon(Icons.broken_image, size: 40),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           book.title,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//           ),
//           maxLines: 2,
//           overflow: TextOverflow.ellipsis,
//         ),
//         const SizedBox(height: 4),
//         Text(
//           book.author,
//           style: const TextStyle(
//             fontSize: 12,
//             color: Colors.grey,
//           ),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ],
//     );
//   }
// }


