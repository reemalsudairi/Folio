import 'package:flutter/material.dart'; // Importing Flutter Material Design package
import 'package:folio/services/google_books_service.dart'; // Importing the custom service to interact with Google Books API

import 'book_details_page.dart'; // Importing the BookDetailsPage to navigate to it

class BookListPage extends StatefulWidget {
  final String searchTerm; // The search term or category to display books for
  final bool isCategory; // Boolean flag to indicate if search term is a category or a general search term

  const BookListPage({
    super.key,
    required this.searchTerm, // Required search term parameter for constructor
    required this.isCategory, // Required isCategory parameter for constructor
  });

  @override
  _BookListPageState createState() => _BookListPageState(); // Create the state for this widget
}

class _BookListPageState extends State<BookListPage> {
  final GoogleBooksService _googleBooksService = GoogleBooksService(); // Initialize the service to interact with Google Books API
  List<dynamic> _books = []; // List to store the books fetched from the API
  bool _isLoading = true; // Boolean to check if data is still loading
  String _errorMessage = ''; // String to store any error message

  @override
  void initState() {
    super.initState();
    _loadBooks(); // Load books when the widget is initialized
  }

  // Function to load books from Google Books API
  void _loadBooks() async {
    try {
      final books = await _googleBooksService.searchBooks(
        widget.searchTerm, // Pass the search term from the widget
        isCategory: widget.isCategory, // Pass the isCategory flag
      );
      if (books.isEmpty) {
        setState(() => _errorMessage = "No books found for '${widget.searchTerm}'."); // Show message if no books found
      } else {
        setState(() => _books = books); // Store the fetched books in _books list
      }
    } catch (e) {
      // Catch any error during API call
      setState(() {
        _isLoading = false; // Stop loading
        _errorMessage = 'Error loading books: ${e.toString()}'; // Set error message
      });
    } finally {
      setState(() => _isLoading = false); // Stop loading after API call is finished
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3), // Set background color of the page
      appBar: AppBar(
        title: Text(
          widget.isCategory
              ? widget.searchTerm // If isCategory is true, display the searchTerm directly
              : "Results for '${widget.searchTerm}'", // Else, display "Results for 'searchTerm'"
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Color(0xFF351F1F), // Dark text color for the title
          ),
        ),
        centerTitle: true, // Center the title in the AppBar
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show a loading indicator if books are being fetched
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage)) // Show error message if there is an error
              : Padding(
                  padding: const EdgeInsets.all(12.0), // Padding around the GridView
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Display 2 books per row
                      childAspectRatio: 0.66, // Ensure the aspect ratio of the grid items is consistent
                      crossAxisSpacing: 10, // Horizontal space between grid items
                      mainAxisSpacing: 10, // Vertical space between grid items
                    ),
                    itemCount: _books.length, // Number of items in the grid
                    itemBuilder: (context, index) {
                      final book = _books[index]; // Get each book from the list
                      final title = book['volumeInfo']['title'] ?? 'No title'; // Get the book title, fallback to 'No title' if null
                      final authors =
                          book['volumeInfo']['authors']?.join(', ') ??
                              'Unknown author'; // Get the authors, fallback to 'Unknown author' if null
                      final thumbnail = book['volumeInfo']['imageLinks'] != null
                          ? book['volumeInfo']['imageLinks']['thumbnail'] // Get the book cover thumbnail
                          : 'https://via.placeholder.com/150'; // Fallback to a placeholder image if thumbnail is not available
                      final bookId = book['id']; // Fetch the unique book ID

                      return GestureDetector(
                        onTap: () {
                          // On tap, navigate to the BookDetailsPage and pass the bookId
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BookDetailsPage(bookId: bookId),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30.0), // Rounded corners for the book card
                          child: Container(
                            color: const Color(0xFFF8F8F3), // Background color for each book item
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center, // Center align the items in the column
                              children: [
                                // Flexible widget to ensure image and text sizes adjust properly
                                Flexible(
                                  flex: 5, // Image takes up most of the space
                                  child: AspectRatio(
                                    aspectRatio: 0.66, // Maintain aspect ratio for all book covers
                                    child: Image.network(
                                      thumbnail, // Book cover image from the API
                                      fit: BoxFit.cover, // Make sure the image covers the entire space without distortion
                                      width: double.infinity, // Stretch the image to fill the width of the container
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(Icons.error), // Show an error icon if the image fails to load
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // Flexible widget to ensure text is spaced out properly
                                Flexible(
                                  flex: 2, // Title takes less space than the image
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0), // Padding around the title text
                                    child: Text(
                                      title, // Display the book title
                                      style: const TextStyle(
                                        color: Color(0xFF351F1F), // Dark color for the title
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold, // Bold text for the title
                                      ),
                                      textAlign: TextAlign.center, // Center the title text
                                      maxLines: 2, // Limit the title to 2 lines
                                      overflow: TextOverflow.ellipsis, // Truncate the title with ellipsis if it's too long
                                    ),
                                  ),
                                ),
                                // Flexible widget to ensure text is spaced out properly
                                Flexible(
                                  flex: 1, // Author section takes less space than title
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0), // Padding around the author text
                                    child: Text(
                                      authors, // Display the author names
                                      style: const TextStyle(
                                        color: Color(0xFF9b9b9b), // Grey color for the authors
                                        fontSize: 15, // Font size for author text
                                      ),
                                      textAlign: TextAlign.center, // Center the author text
                                      maxLines: 1, // Limit author names to 1 line
                                      overflow: TextOverflow.ellipsis, // Truncate the author names with ellipsis if too long
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

