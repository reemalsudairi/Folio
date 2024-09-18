import 'package:flutter/material.dart';
import 'package:folio/services/google_books_service.dart';

import 'book_details_page.dart';

class BookListPage extends StatefulWidget {
  final String searchTerm;
  final bool isCategory;

  const BookListPage({
    Key? key,
    required this.searchTerm,
    required this.isCategory,
  }) : super(key: key);

  @override
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final GoogleBooksService _googleBooksService = GoogleBooksService();
  List<dynamic> _books = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() async {
    try {
      final books = await _googleBooksService.searchBooks(
        widget.searchTerm,
        isCategory: widget.isCategory,
      );
      if (books.isEmpty) {
        setState(() => _errorMessage = "No books found for '${widget.searchTerm}'.");
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
        title: Text(
          widget.isCategory ? widget.searchTerm : "Results for '${widget.searchTerm}'",
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Display 2 books per row
                      childAspectRatio: 0.66,
                      crossAxisSpacing: 40,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: _books.length,
                    itemBuilder: (context, index) {
                      final book = _books[index];
                      final title = book['volumeInfo']['title'] ?? 'No title';
                      final authors = book['volumeInfo']['authors']?.join(', ') ?? 'Unknown author';
                      final thumbnail = book['volumeInfo']['imageLinks'] != null
                          ? book['volumeInfo']['imageLinks']['thumbnail']
                          : 'https://via.placeholder.com/150';
                      final bookId = book['id']; // Fetch the book ID here

                      return GestureDetector(
                        onTap: () {
                          // Navigate to BookDetailsPage and pass the bookId
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailsPage(bookId: bookId),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            color: const Color(0xFFF8F8F3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Image.network(
                                    thumbnail,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.error),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Color(0xFF351F1F),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8.0, right: 8.0, bottom: 8.0),
                                  child: Text(
                                    authors,
                                    style: const TextStyle(
                                      color: Color(0xFF9b9b9b),
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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