import 'package:flutter/material.dart';
import 'package:folio/services/google_books_service.dart';

class BookDetailsPage extends StatefulWidget {
  final String bookId;

  const BookDetailsPage({Key? key, required this.bookId}) : super(key: key);

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  final GoogleBooksService _googleBooksService = GoogleBooksService();
  Map<String, dynamic>? bookDetails;
  bool _isLoading = true;
  String _errorMessage = '';

  // This will store the selected option from the dropdown
  String selectedOption = 'Save'; // The default selected option

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
  }

  // Fetch book details using the book ID
  void _loadBookDetails() async {
    try {
      final details = await _googleBooksService.getBookDetails(widget.bookId);
      setState(() {
        bookDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading book details: ${e.toString()}';
      });
    }
  }

  // Helper function to remove HTML tags and star emoji from the description
  String removeHtmlTags(String htmlText) {
    // Regular expression to remove HTML tags
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);

    // Remove HTML tags
    String cleanText = htmlText.replaceAll(exp, '');

    // Remove star emoji ratings
    cleanText = cleanText.replaceAll('⭐', ''); // Remove star symbols

    return cleanText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      appBar: AppBar(
        title: const Text(
          'Book Details',
          style: TextStyle(
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Book cover image
                        Image.network(
                          bookDetails?['volumeInfo']['imageLinks']?['thumbnail'] ??
                              'https://via.placeholder.com/150',
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.error),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Title
                        Text(
                          bookDetails?['volumeInfo']['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Color(0xFF351F1F),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Author
                        Text(
                          'By ${bookDetails?['volumeInfo']['authors']?.join(', ') ?? 'Unknown Author'}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF9b9b9b),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Save button with dropdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // Your onPressed logic here (if needed)
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF790AD),
                                foregroundColor: Color.fromARGB(255, 255, 255, 255), // Set button background color
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Display the currently selected option
                                  Text(
                                    selectedOption, // Use the selectedOption variable as button text
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  PopupMenuButton<String>(
                                    onSelected: (String value) {
                                      setState(() {
                                        selectedOption = value; // Update the selected option
                                      });
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'Save',
                                          child: ListTile(
                                            leading: Icon(Icons.bookmark),
                                            title: Text('Save'),
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'Currently reading',
                                          child: ListTile(
                                            leading: Icon(Icons.menu_book_sharp),
                                            title: Text('Currently reading'),
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'Finished',
                                          child: ListTile(
                                            leading: Icon(Icons.check_circle),
                                            title: Text('Finished'),
                                          ),
                                        ),
                                      ];
                                    },
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Display selected option (for testing purposes)
                        Text(
                          'Selected option: $selectedOption',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        // Tabs (About, Reviews, Clubs)
                        DefaultTabController(
                          length: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TabBar(
                                labelColor: const Color(0xFF351F1F),
                                unselectedLabelColor: const Color(0xFF351F1F),
                                indicatorColor: const Color(0xFF351F1F),
                                tabs: const [
                                  Tab(text: 'About'),
                                  Tab(text: 'Reviews'),
                                  Tab(text: 'Clubs'),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 300,
                                child: TabBarView(
                                  children: [
                                    // About Tab
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Release year, number of pages, rating
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('Released in'),
                                                Text(
                                                  bookDetails?['volumeInfo']
                                                              ['publishedDate']
                                                          ?.substring(0, 4) ??
                                                      'N/A',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                const Text('Number of pages'),
                                                Text(
                                                  bookDetails?['volumeInfo']
                                                          ['pageCount']
                                                      ?.toString() ??
                                                      'N/A',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text('Ratings'),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      color: const Color(0xFFF790AD),
                                                      size: 18,
                                                    ),
                                                    Text(
                                                      bookDetails?['volumeInfo']
                                                                  [
                                                                  'averageRating']
                                                              ?.toString() ??
                                                          'N/A',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        // Description label and content
                                        const Text(
                                          'Description',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 10),  // Adds some space between "Description" and the actual content
                                        // Description with HTML tags and stars removed
                                        SizedBox(
                                          height: 200,  // Set the maximum height for the description
                                          child: SingleChildScrollView(
                                            child: Text(
                                              removeHtmlTags(bookDetails?['volumeInfo']['description'] ?? 'No description available.'),
                                              style: const TextStyle(fontSize: 16),
                                              textAlign: TextAlign.justify,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Reviews Tab
                                    const Center(
                                      child: Text('No reviews available.'),
                                    ),
                                    // Clubs Tab
                                    const Center(
                                      child: Text('No clubs discussing this book currently.'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}