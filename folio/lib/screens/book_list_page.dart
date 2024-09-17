import 'package:flutter/material.dart';
import 'package:folio/services/google_books_service.dart';

class BookListPage extends StatefulWidget {
  final String searchTerm; // Can be category or book name
  final bool
      isCategory; // Determines if we are searching by category or book name

  const BookListPage(
      {super.key, required this.searchTerm, required this.isCategory});

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
        isCategory: widget.isCategory, // true for category, false for book name
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
                      crossAxisCount: 2, // Display 2 books per row
                      childAspectRatio:
                          0.6, // Adjust aspect ratio to make book covers taller
                      crossAxisSpacing: 20, // Horizontal space between books
                      mainAxisSpacing: 20, // Vertical space between books
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

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F3),
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFFF8F8F3),
                              spreadRadius: 2,
                              blurRadius: 4,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Expanded maximizes the cover size within the container
                              Expanded(
                                flex: 3, // Give more space to the cover
                                child: Image.network(
                                  thumbnail,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                        child: Icon(Icons
                                            .error)); // Error icon if image fails to load
                                  },
                                ),
                              ),
                              // Reduced padding for title to prioritize the cover size
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Color(0xFF351F1F),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Reduced padding for authors to prioritize the cover size
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0, bottom: 8.0),
                                child: Text(
                                  authors,
                                  style: const TextStyle(
                                    color: Color(0xFF9b9b9b),
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
