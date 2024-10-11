import 'package:flutter/material.dart'; // Importing Flutter Material Design package
import 'package:folio/services/google_books_service.dart'; // Importing the custom service to interact with Google Books API

class SelectBookPage extends StatefulWidget {
  const SelectBookPage({Key? key}) : super(key: key);

  @override
  _SelectBookPageState createState() =>
      _SelectBookPageState(); // Create the state for this widget
}

class _SelectBookPageState extends State<SelectBookPage> {
  final GoogleBooksService _googleBooksService =
      GoogleBooksService(); // Initialize the service to interact with Google Books API
  List<dynamic> _books =
      []; // List to store the random books fetched from the API
  bool _isLoading = true; // Boolean to check if data is still loading
  String _errorMessage = ''; // String to store any error message

  @override
  void initState() {
    super.initState();
    _loadRandomBooks(); // Load random books when the widget is initialized
  }

  // Function to load 30 best-selling books from Google Books API
  void _loadRandomBooks() async {
    try {
      final books = await _googleBooksService
          .fetchBestSellingBooks(); // Fetch 30 best-selling books
      if (books.isEmpty) {
        setState(() => _errorMessage = "No books found.");
      } else {
        setState(
            () => _books = books); // Store the fetched books in _books list
      }
    } catch (e) {
      // Catch any error during API call
      setState(() {
        _isLoading = false; // Stop loading
        _errorMessage =
            'Error loading books: ${e.toString()}'; // Set error message
      });
    } finally {
      setState(
          () => _isLoading = false); // Stop loading after API call is finished
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select a Book', // Title for the app bar
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Color(0xFF351F1F), // Dark text color for the title
          ),
        ),
        centerTitle: true, // Center the title in the AppBar
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(), // Show a loading indicator if books are being fetched
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                      _errorMessage), // Show error message if there is an error
                )
              : Padding(
                  padding:
                      const EdgeInsets.all(12.0), // Padding around the GridView
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Display 2 books per row
                      childAspectRatio:
                          0.66, // Ensure the aspect ratio of the grid items is consistent
                      crossAxisSpacing:
                          10, // Horizontal space between grid items
                      mainAxisSpacing: 10, // Vertical space between grid items
                    ),
                    itemCount: _books.length, // Number of items in the grid
                    itemBuilder: (context, index) {
                      final book = _books[index]; // Get each book from the list
                      final title = book['volumeInfo']['title'] ??
                          'No title'; // Get the book title, fallback to 'No title' if null
                      final authors = book['volumeInfo']['authors']
                              ?.join(', ') ??
                          'Unknown author'; // Get the authors, fallback to 'Unknown author' if null
                      final thumbnail = book['volumeInfo']['imageLinks'] != null
                          ? book['volumeInfo']['imageLinks']
                              ['thumbnail'] // Get the book cover thumbnail
                          : 'https://via.placeholder.com/150'; // Fallback to a placeholder image if thumbnail is not available
                      final bookID = book['id']; // Get the book ID

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(
                            30.0), // Rounded corners for the book card
                        child: Container(
                          color: const Color(
                              0xFFF8F8F3), // Background color for each book item
                          child: Stack(
                            alignment: Alignment
                                .center, // Center the button over the book cover
                            children: [
                              // Book cover image
                              Column(
                                crossAxisAlignment: CrossAxisAlignment
                                    .center, // Center align the items in the column
                                children: [
                                  Flexible(
                                    flex: 5, // Image takes up most of the space
                                    child: AspectRatio(
                                      aspectRatio:
                                          0.66, // Maintain aspect ratio for all book covers
                                      child: Image.network(
                                        thumbnail, // Book cover image from the API
                                        fit: BoxFit
                                            .cover, // Make sure the image covers the entire space without distortion
                                        width: double
                                            .infinity, // Stretch the image to fill the width of the container
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(Icons
                                                .error), // Show an error icon if the image fails to load
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    flex:
                                        2, // Title takes less space than the image
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          8.0), // Padding around the title text
                                      child: Text(
                                        title, // Display the book title
                                        style: const TextStyle(
                                          color: Color(
                                              0xFF351F1F), // Dark color for the title
                                          fontSize: 16,
                                          fontWeight: FontWeight
                                              .bold, // Bold text for the title
                                        ),
                                        textAlign: TextAlign
                                            .center, // Center the title text
                                        maxLines:
                                            2, // Limit the title to 2 lines
                                        overflow: TextOverflow
                                            .ellipsis, // Truncate the title with ellipsis if it's too long
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    flex:
                                        1, // Author section takes less space than title
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0,
                                          right: 8.0,
                                          bottom:
                                              8.0), // Padding around the author text
                                      child: Text(
                                        authors, // Display the author names
                                        style: const TextStyle(
                                          color: Color(
                                              0xFF9b9b9b), // Grey color for the authors
                                          fontSize:
                                              15, // Font size for author text
                                        ),
                                        textAlign: TextAlign
                                            .center, // Center the author text
                                        maxLines:
                                            1, // Limit author names to 1 line
                                        overflow: TextOverflow
                                            .ellipsis, // Truncate the author names with ellipsis if too long
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // "Select" button over the book cover
                              Positioned(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Return the selected book ID and title back to the previous page
                                    Navigator.pop(context, {
                                      'id': bookID,
                                      'title': title, // Include the title
                                      'coverImage': thumbnail,
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFFF790AD), // Button color
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12), // Button padding
                                  ),
                                  child: const Text(
                                    'Select', // Button text
                                    style: TextStyle(
                                      color: Colors
                                          .white, // White color for the text
                                      fontSize:
                                          16, // Font size for the button text
                                    ),
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
    );
  }
}
