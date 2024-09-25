import 'package:flutter/material.dart';
import 'package:folio/services/google_books_service.dart';
import 'package:html/parser.dart'; // For parsing HTML

class BookDetailsPage extends StatefulWidget {
  final String bookId;

  const BookDetailsPage({super.key, required this.bookId});

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  final GoogleBooksService _googleBooksService = GoogleBooksService();
  Map<String, dynamic>? bookDetails;
  bool _isLoading = true;
  String _errorMessage = '';
  
  String selectedOption = 'Save'; // The default selected option
  int _selectedIndex = 0; // To track selected tab

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
  }

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

  String removeHtmlTags(String htmlText) {
    final document = parse(htmlText);
    String parsedText = document.body?.text ?? '';
    parsedText = parsedText.replaceAll('⭐', ''); // Remove star symbols
    return parsedText;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                          bookDetails?['volumeInfo']['imageLinks']?['thumbnail'] ?? 'https://via.placeholder.com/150',
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.error));
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
                          style: const TextStyle(fontSize: 18, color: Color(0xFF9b9b9b)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Save button with dropdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 250, // Fixed width for button
                              child: ElevatedButton(
                                onPressed: () {
                                  // Your onPressed logic here
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF790AD), // Pink background
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), // Padding
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20), // Rounded corners
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // Align text and dropdown
                                  children: [
                                    Text(
                                      selectedOption, // Current selected option (Save, Currently reading, Finished)
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white, // White text
                                        fontWeight: FontWeight.bold, // Bold text
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (String value) {
                                        setState(() {
                                          selectedOption = value; // Update selected option
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
                                        Icons.arrow_drop_down, // Dropdown icon
                                        color: Colors.white, // White icon to match the button color
                                      ),
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10), // Dropdown menu rounding
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Custom TabBar design
                      Column(
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TextButton(
          onPressed: () => _onItemTapped(0),
          child: Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _selectedIndex == 0 ? Colors.brown[800] : Colors.grey[600],
            ),
          ),
        ),
        TextButton(
          onPressed: () => _onItemTapped(1),
          child: Text(
            'Clubs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _selectedIndex == 1 ? Colors.brown[800] : Colors.grey[600],
            ),
          ),
        ),
        TextButton(
          onPressed: () => _onItemTapped(2),
          child: Text(
            'Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _selectedIndex == 2 ? Colors.brown[800] : Colors.grey[600],
            ),
          ),
        ),
      ],
    ),
    Stack(
      fit: StackFit.passthrough,
      children: [
        Container(
          height: 2,
          color: Colors.grey[300],
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        AnimatedPositioned(
  duration: const Duration(milliseconds: 300),
  left: _getWordMiddlePosition(_selectedIndex, MediaQuery.of(context).size.width) - _calculateTextWidth(
      _selectedIndex == 0
          ? 'About'
          : _selectedIndex == 1
              ? 'Clubs'
              : 'Reviews') /
      2, // Position in the middle of the selected word
  top: -1,
  child: Container(
    height: 4,
    width: _calculateTextWidth(
      _selectedIndex == 0 ? 'About' : _selectedIndex == 1 ? 'Clubs' : 'Reviews'),
    color: Colors.brown[800],
  ),
),
      ],
    ),
  ],
),
                        const SizedBox(height: 20),
                        // Tab content based on selected index
                        if (_selectedIndex == 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Release year, number of pages, custom rating
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Released in'),
                                      Text(
                                        bookDetails?['volumeInfo']['publishedDate']?.substring(0, 4) ?? 'N/A',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Text('Number of pages'),
                                      Text(
                                        bookDetails?['volumeInfo']['pageCount']?.toString() ?? 'N/A',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Ratings'),
                                      Row(
                                        children: [
                                          // Display frontend-only rating with 1 pink star
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                color: Color(0xFFF790AD), // Pink color for one filled star
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            '-', // Set the rating to 1 star
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
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
                              const SizedBox(height: 10), // Adds some space between "Description" and the actual content
                              // Full Description with HTML tags removed
                              SizedBox(
                                height: 200, // Set a height for the description
                                child: SingleChildScrollView(
                                  child: Text(
                                    removeHtmlTags(bookDetails?['volumeInfo']['description'] ?? 'No description available.'),
                                    style: const TextStyle(fontSize: 16),
                                    textAlign: TextAlign.justify,
                                    softWrap: true, // Ensure text wraps naturally at word boundaries
                                    overflow: TextOverflow.clip, // Clip any overflowing text
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (_selectedIndex == 1)
                          Center(
                            child: Text(
                              'No clubs discussing this book currently.',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[800],
                              ),
                            ),
                          ),
                        if (_selectedIndex == 2)
                          Center(
                            child: Text(
                              'No reviews available.',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[800],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
   double _calculateTextWidth(String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }

 double _getWordMiddlePosition(int index, double screenWidth) {
  // Widths of each word using the same text style
  final wordWidths = [
    _calculateTextWidth('About'),
    _calculateTextWidth('Clubs'),
    _calculateTextWidth('Reviews'),
  ];

  // Calculate the total width occupied by the words
  double totalWordsWidth = wordWidths.reduce((a, b) => a + b);
  // Calculate the space left to distribute between the words (padding)
  double spaceBetweenWords = (screenWidth - totalWordsWidth) / 3; // 3 words, 3 spaces (between words)

  // Position based on index (for left margin)
  double position = spaceBetweenWords / 2; // Start from the middle of the first space
  for (int i = 0; i < index; i++) {
    position += wordWidths[i] + spaceBetweenWords;
  }

  // Return middle of the word
  return position + (wordWidths[index] / 2);
}
}