import 'package:flutter/material.dart';
import 'package:folio/services/google_books_service.dart';
import 'package:html/parser.dart'; // For parsing HTML
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class BookDetailsPage extends StatefulWidget {
  final String bookId;
  final String userId; // Add this line

  const BookDetailsPage(
      {super.key, required this.bookId, required this.userId});

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  final GoogleBooksService _googleBooksService = GoogleBooksService();
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance for database operations
  String? userId; // User ID from Firebase Authentication
  Map<String, dynamic>? bookDetails;
  bool _isLoading = true;
  bool _isUserIdLoaded = false; // Flag to track whether user ID is loaded
  String _errorMessage = '';

  String selectedOption = 'Add to'; // Default button text
  int _selectedIndex = 0; // To track selected tab

  @override
  void initState() {
    super.initState();
    _fetchUserIdAndLoadDetails(); // Fetch user ID from Firebase Auth
  }

  // Fetch the user ID from Firebase Authentication
  Future<void> _fetchUserIdAndLoadDetails() async {
    User? user = FirebaseAuth.instance.currentUser;

    // Fix: Pass `userId` from `widget` if Firebase is not providing it
    if (user != null) {
      setState(() {
        userId = user.uid; // Set the userId from Firebase
        _isUserIdLoaded = true; // Set the flag to true
      });
      _loadBookDetails(); // Load book details after getting userId
    } else if (widget.userId.isNotEmpty) {
      // Use the passed `userId` if Firebase user is null
      setState(() {
        userId = widget.userId;
        _isUserIdLoaded = true;
      });
      _loadBookDetails();
    } else {
      setState(() {
        _errorMessage = 'No user is logged in.';
      });
    }
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

  // Method to remove HTML tags from a string
  String removeHtmlTags(String htmlText) {
    final document = parse(htmlText);
    String parsedText = document.body?.text ?? '';
    parsedText = parsedText.replaceAll('⭐', ''); // Remove star symbols
    return parsedText;
  }

  void _onMenuSelected(String value) {
    if (value != selectedOption) {
      _moveBookBetweenLists(selectedOption,
          value); // Move book between lists when option is changed
      setState(() {
        selectedOption = value;
      });
    }
  }
Future<void> _moveBookBetweenLists(String currentList, String newList) async {
  // Ensure userId is set
  if (!_isUserIdLoaded) {
    print('Error: User ID is not loaded yet!');
    return;
  }

  final currentUserId = userId ?? widget.userId;

  // ignore: unnecessary_null_comparison
  if (currentUserId == null || currentUserId.isEmpty) {
    print('Error: User ID is empty!');
    return;
  }

  if (widget.bookId.isEmpty) {
    print('Error: Book ID is empty!');
    return;
  }

  try {
    print('Moving book from $currentList to $newList');

    // Remove the book from all lists except the new one
    final List<String> allLists = ['save', 'currently reading', 'finished'];

    for (var list in allLists) {
      if (list != newList.toLowerCase()) {
        print('Removing book from $list');
        await _firestore
            .collection('reader')
            .doc(currentUserId)
            .collection(list)
            .doc(widget.bookId)
            .delete();

        // If the book was in "finished", decrement the yearly goal
        if (list == 'Finished') {
          print('Attempting to decrement booksRead...');
          await _decrementBooksRead();
        }
      }
    }

// Add the book to the new list
await _firestore
    .collection('reader')
    .doc(currentUserId)
    .collection(newList.toLowerCase())
    .doc(widget.bookId)
    .set({
  'bookID': widget.bookId,
  'timestamp': FieldValue.serverTimestamp(),
});

print('newList value is: $newList'); // Debugging log

// If the book is moved to "finished", increment the yearly goal
if (newList == 'Finished') {
  print('Entering _incrementBooksRead block...');  // Debugging log
  await _incrementBooksRead();
} else {
  print('Not entering _incrementBooksRead, newList is not "finished"'); // Debugging log
}


    print('Successfully moved the book to $newList');
  } catch (e) {
    print('Error moving book: $e');
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



  // Handle tab switching
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_isUserIdLoaded) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Book cover image
             ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: Image.network(
    bookDetails?['volumeInfo']['imageLinks']?['thumbnail'] ?? 'https://via.placeholder.com/150',
    height: 250,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        height: 250,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, size: 40),
      );
    },
  ),
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

              // Add to Library button with dropdown and checkmark
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300, // Fixed width for button
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF790AD),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Center the text inside the button
                        children: [
                          Flexible(
                            child: Text(
                              selectedOption == 'Add to'
                                  ? 'Add to'
                                  : 'Added to $selectedOption',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.fade, // Handle long text
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                          if (selectedOption != 'Add to')
                            const Icon(Icons.check, color: Colors.white),
                          PopupMenuButton<String>(
                            onSelected: _onMenuSelected, // Enable selection
                            itemBuilder: (BuildContext context) {
                              return <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'Save',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.bookmark,
                                      color: selectedOption == 'Save'
                                          ? const Color(0xFFF790AD)
                                          : null,
                                    ),
                                    title: const Text('Save'),
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Currently Reading',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.menu_book,
                                      color:
                                          selectedOption == 'Currently Reading'
                                              ? const Color(0xFFF790AD)
                                              : null,
                                    ),
                                    title: const Text('Currently Reading'),
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Finished',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.check_circle,
                                      color: selectedOption == 'Finished'
                                          ? const Color(0xFFF790AD)
                                          : null,
                                    ),
                                    title: const Text('Finished'),
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
                            color: _selectedIndex == 0
                                ? Colors.brown[800]
                                : Colors.grey[600],
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
                            color: _selectedIndex == 1
                                ? Colors.brown[800]
                                : Colors.grey[600],
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
                            color: _selectedIndex == 2
                                ? Colors.brown[800]
                                : Colors.grey[600],
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
                        left: _getWordMiddlePosition(_selectedIndex,
                                MediaQuery.of(context).size.width) -
                            _calculateTextWidth(_selectedIndex == 0
                                    ? 'About'
                                    : _selectedIndex == 1
                                        ? 'Clubs'
                                        : 'Reviews') /
                                2, // Position in the middle of the selected word
                        top: -1,
                        child: Container(
                          height: 4,
                          width: _calculateTextWidth(_selectedIndex == 0
                              ? 'About'
                              : _selectedIndex == 1
                                  ? 'Clubs'
                                  : 'Reviews'),
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
                              bookDetails?['volumeInfo']['publishedDate']
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Number of pages'),
                            Text(
                              bookDetails?['volumeInfo']['pageCount']
                                      ?.toString() ??
                                  'N/A',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
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
                                      color: Color(
                                          0xFFF790AD), // Pink color for one filled star
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
                    const SizedBox(height: 10),
                    // Full Description with HTML tags removed
                    SingleChildScrollView(
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          Text(
                            removeHtmlTags(bookDetails?['volumeInfo']
                                    ['description'] ??
                                'No description available.'),
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.justify,
                            softWrap: true,
                          ),
                        ],
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
    final wordWidths = [
      _calculateTextWidth('About'),
      _calculateTextWidth('Clubs'),
      _calculateTextWidth('Reviews'),
    ];

    double totalWordsWidth = wordWidths.reduce((a, b) => a + b);
    double spaceBetweenWords = (screenWidth - totalWordsWidth) / 3;

    double position = spaceBetweenWords / 2;
    for (int i = 0; i < index; i++) {
      position += wordWidths[i] + spaceBetweenWords;
    }

    return position + (wordWidths[index] / 2);
  }
}