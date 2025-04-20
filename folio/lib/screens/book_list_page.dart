import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter/material.dart';
import 'package:folio/services/google_books_service.dart';
import 'book_details_page.dart';

class BookListPage extends StatefulWidget {
  final String searchTerm;
  final bool isCategory;

  const BookListPage({
    super.key,
    required this.searchTerm,
    required this.isCategory,
  });

  @override
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final GoogleBooksService _googleBooksService = GoogleBooksService();
  List<dynamic> _books = [];
  bool _isLoading = true;
  String _errorMessage = '';
  // Define a variable to store the current user's ID
    String? userId;  //L26

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _fetchUserId(); // Fetch user ID from Firebase Auth
  }

  // This method is called to fetch the current user's ID from Firebase Authentication
  Future<void> _fetchUserId() async { //L36
  // Get the currently signed-in user from Firebase
  User? user = FirebaseAuth.instance.currentUser; //L38

  // If the user exists, update the userId state variable
  if (user != null) {  //L41
    setState(() {  //L42
      userId = user.uid; // Save the user's unique ID    //L43
    });  //L44
    }
  }

  void _loadBooks() async {
    try {
      final books = await _googleBooksService.searchBooks(
        widget.searchTerm,
        isCategory: widget.isCategory,
      );
      if (books.isEmpty) {
        setState(
            () => _errorMessage = "No books found for '${widget.searchTerm}'.");
      } else {
        setState(() => _books = books);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading books: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      appBar: AppBar(
         backgroundColor: const Color(0xFFF8F8F3),
        title: Text(
          widget.isCategory
              ? widget.searchTerm
              : "Results for '${widget.searchTerm}'",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Color(0xFF351F1F),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.66,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _books.length,
                    itemBuilder: (context, index) {
                      final book = _books[index];
                      final title = book['volumeInfo']['title'] ?? 'No title';
                      final authors =
                          book['volumeInfo']['authors']?.join(', ') ??
                              'Unknown author';
                      final thumbnail = book['volumeInfo']['imageLinks'] != null
                          ? book['volumeInfo']['imageLinks']['thumbnail']
                          : 'https://via.placeholder.com/150';
                      final bookId = book['id'];

                      return GestureDetector(

                        // Inside the itemBuilder, this section handles what happens when a book is tapped
                          onTap: () {  //117
                            // Check if userId is not null (user is signed in)
                            if (userId != null) {  //L119
                              // Navigate to the BookDetailsPage, passing both bookId and userId
                              Navigator.push(  //L121
                                context,  //L122
                                MaterialPageRoute(  //L123
                                  builder: (context) => BookDetailsPage(  //L124
                                    bookId: bookId, // The selected book's ID  //L125
                                    userId: userId!, // The current user's ID   //L126
                                  ),
                                ),
                              );
                            }
                            return;
                          },

                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Container(
                            color: const Color(0xFFF8F8F3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  flex: 5,
                                  child: AspectRatio(
                                    aspectRatio: 0.66,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          10), // Apply circular border radius
                                      child: Image.network(
                                        thumbnail,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                              child: Icon(Icons.error));
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                Flexible(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8.0, right: 8.0, bottom: 8.0),
                                    child: Text(
                                      authors,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}