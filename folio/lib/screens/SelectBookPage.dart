import 'package:flutter/material.dart';
import 'package:folio/services/google_books_service.dart';

class SelectBookPage extends StatefulWidget {
  const SelectBookPage({Key? key}) : super(key: key);

  @override
  _SelectBookPageState createState() => _SelectBookPageState();
}

class _SelectBookPageState extends State<SelectBookPage> {
  final GoogleBooksService _googleBooksService = GoogleBooksService();
  List<dynamic> _books = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController =
      TextEditingController(); // Controller for search bar

  @override
  void initState() {
    super.initState();
    _loadBestSellingBooks(); // Load best-selling books initially
  }

  // Function to load 30 best-selling books from Google Books API
  void _loadBestSellingBooks() async {
    try {
      final books = await _googleBooksService.fetchBestSellingBooks();
      if (books.isEmpty) {
        setState(() => _errorMessage = "No books found.");
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

  // Function to search for books based on user input
  void _searchAndNavigate(BuildContext context, {String value = ''}) async {
    final searchTerm =
        value.isEmpty ? _searchController.text.trim() : value.trim();

    if (searchTerm.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final books = await _googleBooksService
            .searchBooks(searchTerm); // Search books by title
        if (books.isEmpty) {
          setState(() => _errorMessage = "No books found for '$searchTerm'.");
        } else {
          setState(() => _books = books);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error searching for books: ${e.toString()}';
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select a Book',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Color(0xFF351F1F),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for a book',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                filled: true,
                fillColor: const Color.fromARGB(255, 255, 255, 255),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 20.0),
              ),
              onSubmitted: (String value) =>
                  _searchAndNavigate(context, value: value),
            ),
          ),
          // "Bestsellers" label
          const Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Bestsellers",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFF351F1F),
                ),
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage))
                  : Expanded(
                      child: Padding(
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
                            final title =
                                book['volumeInfo']['title'] ?? 'No title';
                            final authors =
                                book['volumeInfo']['authors']?.join(', ') ??
                                    'Unknown author';
                            final thumbnail =
                                book['volumeInfo']['imageLinks'] != null
                                    ? book['volumeInfo']['imageLinks']
                                        ['thumbnail']
                                    : 'https://via.placeholder.com/150';
                            final bookID = book['id'];

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(30.0),
                              child: Container(
                                color: const Color(0xFFF8F8F3),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          flex: 5,
                                          child: AspectRatio(
                                            aspectRatio: 0.66,
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
                                        Flexible(
                                          flex: 2,
                                          child: Padding(
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
                                        ),
                                        Flexible(
                                          flex: 1,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0,
                                                right: 8.0,
                                                bottom: 8.0),
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
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context, {
                                            'id': bookID,
                                            'title': title,
                                            'coverImage': thumbnail,
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFF790AD),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 12),
                                        ),
                                        child: const Text(
                                          'Select',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}
