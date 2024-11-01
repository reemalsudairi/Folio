import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter/material.dart';
import 'package:folio/screens/OtherProfile/otherprofile.dart';
import 'package:folio/screens/bookclubs_page.dart';
import 'package:folio/screens/viewClub.dart';
import 'package:folio/screens/writeReview.dart';
import 'package:folio/services/google_books_service.dart';
import 'package:html/parser.dart'; // For parsing HTML

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
  List<Club> bookClubs = []; // Initialize the bookClubs list

  @override
  void initState() {
    super.initState();
    _fetchUserIdAndLoadDetails();
    fetchBookClubs(widget.bookId);
    _loadBookDetails(); // Fetch the book details
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
    setState(() {
      _isLoading = true; // Start loading
      _errorMessage = ''; // Clear any previous errors
    });

    print('Loading: $_isLoading (Before fetching data)');

    try {
      final details = await _googleBooksService
          .getBookDetails(widget.bookId); // Fetch book details

      final List<String> allLists = ['save', 'currently reading', 'finished'];
      String currentList = 'Add to'; // Default button state

      for (var list in allLists) {
        var doc = await _firestore
            .collection('reader')
            .doc(userId)
            .collection(list)
            .doc(widget.bookId)
            .get();

        if (doc.exists) {
          currentList = capitalize(list);
          break;
        }
      }

      setState(() {
        bookDetails = details; // Update book details
        selectedOption = currentList;
        _isLoading = false; // Stop loading
      });

      print(
          'Loading: $_isLoading (After fetching data)'); // Check loading state after
    } catch (e) {
      setState(() {
        _isLoading = false; // Stop loading on error
        _errorMessage = 'Error loading book details: ${e.toString()}';
      });

      print('Error: $_errorMessage'); // Log error
    }
  }

  String capitalize(String input) {
    if (input.isEmpty) return "";
    return input[0].toUpperCase() + input.substring(1);
  }

  // Method to remove HTML tags from a string
  String removeHtmlTags(String htmlText) {
    final document = parse(htmlText);
    String parsedText = document.body?.text ?? '';
    parsedText = parsedText.replaceAll('⭐', ''); // Remove star symbols
    return parsedText;
  }

  void fetchBookClubs(String bookId) {
    try {
      // Listen for changes in the 'clubs' collection where 'currentBookID' matches.
      FirebaseFirestore.instance
          .collection('clubs')
          .where('currentBookID', isEqualTo: bookId)
          .snapshots()
          .listen((clubsSnapshot) {
        List<Club> tempClubs = [];

        for (var doc in clubsSnapshot.docs) {
          // Listen to real-time member count updates for each club.
          fetchMemberCount(doc.id).listen((memberCount) {
            // Create a new Club instance with the updated member count.
            Club club = Club.fromMap(
              doc.data(),
              doc.id,
              memberCount,
            );

            // Update the club in the list or add if not present.
            int existingIndex = tempClubs.indexWhere((c) => c.id == doc.id);
            if (existingIndex >= 0) {
              // Replace the existing club with the updated one.
              tempClubs[existingIndex] = club;
            } else {
              // Add the new club.
              tempClubs.add(club);
            }

            // Update the state with the latest book clubs list.
            setState(() {
              bookClubs = tempClubs;
              _isLoading = false; // Data fetching is complete.
            });
          });
        }
      }, onError: (e) {
        print('Error fetching clubs: $e');
        setState(() {
          _isLoading = false; // Set loading to false in case of error.
        });
      });
    } catch (e) {
      print('Error setting up book clubs listener: $e');
      setState(() {
        _isLoading = false; // Set loading to false in case of error.
      });
    }
  }

  Stream<int> fetchMemberCount(String clubId) {
    try {
      // Listen for real-time updates from the members subcollection
      return FirebaseFirestore.instance
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .snapshots()
          .map((membersSnapshot) {
        // If the members collection is empty, return 1 to indicate only the owner.
        if (membersSnapshot.size == 0) {
          return 1;
        }
        // Otherwise, return the size of the members collection.
        return membersSnapshot.size;
      });
    } catch (e) {
      print('Error fetching member count for club $clubId: $e');
      // Return a stream with a single value of 1 in case of an error.
      return Stream.value(1);
    }
  }

  // Method to build the club grid view
  Widget buildClubGridView(List<Club> bookClubs) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (bookClubs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No clubs are currently discussing this book.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
        ),
        itemCount: bookClubs.length,
        itemBuilder: (context, index) {
          final club = bookClubs[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewClub(clubId: club.id),
                ),
              );
            },
            child: buildClubCard(club),
          );
        },
      );
    }
  }

  Widget buildClubCard(Club club) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ViewClub(clubId: club.id), // Navigate to club details
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            club.picture.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 140, // Adjusted height
                      width: double.infinity,
                      child: Image.network(
                        club.picture,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 140,
                            width: double.infinity,
                            color: Colors.red,
                            child: const Icon(Icons.error, color: Colors.white),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                      ),
                    ),
                  )
                : Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.withOpacity(0.2),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/clubs.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
            const SizedBox(
                height: 8), // Add some space between the image and text

            // Club name
            Flexible(
              child: Text(
                club.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1, // Limit to one line
                overflow:
                    TextOverflow.ellipsis, // Show ellipsis if name is too long
              ),
            ),
            const SizedBox(height: 4),

            // Member count (smaller font size)
            Flexible(
              child: Text(
                '${club.memberCount} members', // Correctly displaying the member count
                style: const TextStyle(
                    fontSize: 14, color: Colors.grey), // Smaller text size
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
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
    if (!_isUserIdLoaded) {
      print('Error: User ID is not loaded yet!');
      return;
    }

    final currentUserId = userId ?? widget.userId;

    if (currentUserId.isEmpty) {
      print('Error: User ID is empty!');
      return;
    }

    if (widget.bookId.isEmpty) {
      print('Error: Book ID is empty!');
      return;
    }

    try {
      // Remove the book from all lists except the new one
      final List<String> allLists = ['save', 'currently reading', 'finished'];

      for (var list in allLists) {
        if (list != newList.toLowerCase()) {
          await _firestore
              .collection('reader')
              .doc(currentUserId)
              .collection(list)
              .doc(widget.bookId)
              .delete();
          if (list == 'Finished') {
            await _decrementBooksRead();
          }
        }
      }
      // Add the book to the new list and save the state
      await _firestore
          .collection('reader')
          .doc(currentUserId)
          .collection(newList.toLowerCase())
          .doc(widget.bookId)
          .set({
        'bookID': widget.bookId,
        'timestamp': FieldValue.serverTimestamp(),
        'listName': newList // Save the list name as part of the book's data
      });
      // If the book is moved to "finished", increment the yearly goal
      if (newList == 'Finished') {
        await _incrementBooksRead();
      }

      _showConfirmationMessage(newList);
    } catch (e) {
      print('Error moving book: $e');
    }
  }

  void _showConfirmationMessage(String listName) {
    String formattedListName = listName[0].toUpperCase() +
        listName.substring(1); // Capitalize the first letter
    showDialog(
      context: context,
      barrierDismissible: false, // Disable dismissal by clicking outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.lightGreen.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                'Added to $formattedListName list successfully!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    // Automatically close the confirmation dialog after 2 seconds
    Future.delayed(const Duration(seconds: 1), () {
      if (Navigator.canPop(context)) {
        // Check if the navigator can pop
        Navigator.pop(context); // Close the confirmation dialog
      }
    });
  }

  Future<void> _incrementBooksRead() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('reader')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        int booksRead = data?['booksRead'] ?? 0;
        int booksGoal = data?['books'] ?? 0;
        bool goalAchievedOnce = data?['goalAchievedOnce'] ??
            false; // Flag to check if message was shown

        // Increment the booksRead field
        booksRead++;
        print('Books read incremented to: $booksRead');

        await FirebaseFirestore.instance
            .collection('reader')
            .doc(userId)
            .update({'booksRead': booksRead});

        // Check if the yearly goal is met and the message has not been shown yet
        if (booksRead >= booksGoal && !goalAchievedOnce) {
          print('Goal reached for the first time!');
          _showGoalAchievedDialog(); // Show the goal achieved dialog

          // Update the flag so the message doesn't appear again for this goal
          await FirebaseFirestore.instance
              .collection('reader')
              .doc(userId)
              .update({'goalAchievedOnce': true});
        }
      } else {
        // Initialize the booksRead field if it doesn't exist
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

  void _showGoalAchievedDialog() {
    if (!mounted) return; // Ensure the widget is still mounted

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.celebration,
                color:
                    Color(0xFFF790AD), // Icon color matching the progress bar
                size: 50,
              ),
              const SizedBox(width: 10),
              Text(
                'Goal Achieved!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800], // Matching design colors
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Congratulations, you have reached your yearly reading goal!',
                style: TextStyle(
                  color:
                      Colors.brown[600], // Keeping a consistent color palette
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: 1, // Full progress to signify the goal is met
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation(Color(0xFFF790AD)),
                minHeight: 13,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
            ],
          ),
        );
      },
    );

    // Automatically close the dialog after 5 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
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
    // Show a loading spinner while loading is true or the user ID isn't loaded yet
    if (_isLoading || !_isUserIdLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_isLoading || bookDetails == null) {
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
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator if still loading
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Book cover image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        bookDetails?['volumeInfo']['imageLinks']
                                ?['thumbnail'] ??
                            'https://via.placeholder.com/150',
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
                      style: const TextStyle(
                          fontSize: 18, color: Color(0xFF9b9b9b)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Add to Library button with dropdown and checkmark
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 300, // Fixed width for button
                          child: PopupMenuTheme(
                            data: const PopupMenuThemeData(
                              color: Colors
                                  .white, // Set the menu background color to white
                            ),
                            child: PopupMenuButton<String>(
                              offset: const Offset(0,
                                  50), // Adjust the offset to move the menu down
                              onSelected: (String value) {
                                _onMenuSelected(value);
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
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
                                      color: selectedOption.toLowerCase() ==
                                              'currently reading'
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
                              ],
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(
                                      0xFFF790AD), // Set the desired button color here
                                  borderRadius: BorderRadius.circular(
                                      20), // Match the button shape
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .center, // Center the text inside the button
                                  children: [
                                    Flexible(
                                      child: Text(
                                        selectedOption == 'Add to'
                                            ? 'Add to'
                                            : selectedOption,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow
                                            .fade, // Handle long text
                                        maxLines: 1,
                                        softWrap: false,
                                      ),
                                    ),
                                    if (selectedOption != 'Add to')
                                      const Icon(Icons.check,
                                          color: Colors.white),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
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
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
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
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'Clubs discussing this book',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF351F1F),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            // Call to build the club grid view
                            buildClubGridView(bookClubs),
                          ],
                        ),
                      ),
                    if (_selectedIndex ==
                        2) // Check if the Reviews tab is selected
                      Stack(
                        children: [
                          // Floating Action Button positioned at the top right corner
                          Positioned(
                            // Adjust this value to control the distance from the top
                            right:
                                16, // Adjust this value to control the distance from the right
                            child: SizedBox(
                              width: 120, // Set the width for the button
                              height: 40, // Set the height for the button
                              child: FloatingActionButton.extended(
                                onPressed: () async {
                                  // Check if the user has already reviewed the book
                                  bool hasReviewed = await _checkIfReviewed(
                                      widget.bookId, userId!);

                                  if (hasReviewed) {
                                    _showReviewAlreadyExistsDialog();
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WriteReviewPage(
                                          bookId: widget.bookId,
                                          userId:
                                              userId!, // Ensure userId is passed.
                                        ),
                                      ),
                                    );
                                  }
                                },
                                label: Text(
                                  'Write a review',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12, // Adjust the text size
                                    color:
                                        Colors.white, // Set text color to white
                                  ),
                                ),
                                backgroundColor: Color(0xFFF790AD),
                                icon: Icon(
                                  Icons.edit,
                                  color:
                                      Colors.white, // Set icon color to white
                                  size: 20, // Adjust the icon size
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      30), // Make button more rounded
                                ),
                              ),
                            ),
                          ),

                          // Add padding to the top of the reviews list to create space below the button
                          Padding(
                            padding: const EdgeInsets.only(
                                top:
                                    50), // Adjust this value for desired spacing
                            child: buildReviewsGridView(widget.bookId),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildReviewsGridView(String bookId) {
    return FutureBuilder<List<Review>>(
      future: fetchReviews(bookId), // Fetch reviews from Firestore
      builder: (BuildContext context, AsyncSnapshot<List<Review>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 20), // Move the message down
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No reviews available.',
                  style: TextStyle(
                    fontSize: 18, // Increased font size for better readability
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 1, 0,
                        0), // Grey color to indicate it's informational
                  ),
                ),
                const SizedBox(height: 8), // Add some space between the texts
                const Text(
                  'Be the first to leave a review and share your thoughts!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey, // Subdued color for secondary message
                  ),
                  textAlign: TextAlign.center, // Center align the grey text
                ),
              ],
            ),
          );
        } else {
          final reviews = snapshot.data!;
          final String currentUserId =
              FirebaseAuth.instance.currentUser?.uid ?? '';

          return ListView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(), // Prevent scrolling if inside a scrollable view
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Card(
                color: Colors.white, // Set the card background color to white
                margin: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 16), // Add horizontal margin
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12), // Adjust card corners
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                      8.0), // Reduced padding for smaller card size
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Navigate to the OtherProfile page for the owner
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtherProfile(
                                    memberId: review
                                        .readerId, // Pass the owner ID to OtherProfile
                                  ),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              backgroundImage: review
                                      .readerProfilePhoto.isNotEmpty
                                  ? NetworkImage(review
                                      .readerProfilePhoto) // Use NetworkImage for network photos
                                  : AssetImage(
                                      'assets/images/profile_pic.png'), // Use AssetImage for the default picture
                              radius: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      review.readerId == currentUserId
                                          ? 'You'
                                          : review.readerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14, // Reduced text size
                                      ),
                                    ),
                                    const SizedBox(
                                        width:
                                            5), // Space between name and time ago
                                    Text(
                                      review
                                          .timeAgo, // Display the time ago string
                                      style: const TextStyle(
                                        fontSize:
                                            12, // Smaller font size for time ago
                                        color: Colors
                                            .grey, // Gray color for time ago text
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                    height: 5), // Space between name and stars
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    if (starIndex < review.rating.toInt()) {
                                      return const Icon(
                                        Icons.star,
                                        color: Color(0xFFF790AD), // Star color
                                        size: 14, // Star size
                                      );
                                    } else if (starIndex ==
                                            review.rating.toInt() &&
                                        review.rating % 1 >= 0.5) {
                                      return const Icon(
                                        Icons.star_half,
                                        color: Color(0xFFF790AD), // Star color
                                        size: 14, // Star size
                                      );
                                    } else {
                                      return const Icon(
                                        Icons.star_border, // Empty star
                                        color: Color(0xFFF790AD), // Star color
                                        size: 14, // Star size
                                      );
                                    }
                                  }),
                                ),
                              ],
                            ),
                          ),
                          if (review.readerId == currentUserId)
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color:
                                      const Color.fromARGB(255, 245, 114, 105)),
                              onPressed: () =>
                                  _confirmDeleteReview(context, review),
                            ),
                          if (review.readerId != currentUserId)
                            Padding(
                              padding: const EdgeInsets.only(
                                  right: 8.0), // Adjust the value as needed
                              child: const Icon(
                                Icons.flag, // Gray flag icon for reporting
                                color: Colors.grey, // Set color to gray
                                size: 23, // Adjust the size of the flag icon
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(
                          height:
                              8), // Adjusted space between the stars and the review text
                      Text(
                        review.reviewText.isNotEmpty
                            ? review.reviewText
                            : '', // Fallback text if review is empty
                        style: const TextStyle(
                            fontSize: 12), // Reduced review text size
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  void _confirmDeleteReview(BuildContext context, Review review) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF790AD).withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.exit_to_app,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to delete this review?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 245, 114, 105),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: const Size(100, 40),
                    ),
                    onPressed: () async {
                      // Attempt to delete the review
                      bool isDeleted = await _deleteReview(context, review);

                      // Close the confirmation dialog
                      Navigator.of(context).pop();

                      if (isDeleted) {
                        // Show success message after confirmation dialog is closed
                        _showSuccessfulMessage(context);
                      } else {
                        // Handle failure to delete (optional)
                      }
                    },
                    child: const Text(
                      'Yes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: const Size(100, 40),
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // Close the dialog without action
                    },
                    child: const Text(
                      'No',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _deleteReview(BuildContext context, Review review) async {
    try {
      // Attempt to delete the review from Firestore
      var snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('bookID', isEqualTo: review.bookId)
          .where('reader_id', isEqualTo: review.readerId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete(); // Delete each document that matches
      }
      setState(() {}); // Refresh the UI after deletion
      return true; // Indicate success
    } catch (e) {
      print("Error deleting review: $e");
      return false; // Indicate failure
    }
  }

  void _showSuccessfulMessage(BuildContext context) {
    // Show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.lightGreen.withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  'Review Removed Successfully!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // This will run when the dialog is closed
    });

    // Automatically close the dialog after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      // Check if the dialog is still displayed
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close the dialog if it's open
      }
    });
  }

// Sample Review class for clarity

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

  // Function to check if the user has reviewed the book
  Future<bool> _checkIfReviewed(String bookId, String userId) async {
    // Access Firestore to check for existing review
    var snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('bookID', isEqualTo: bookId)
        .where('reader_id', isEqualTo: userId)
        .get();

    return snapshot.docs.isNotEmpty; // Returns true if a review exists
  }

// Show a dialog if the user has already reviewed the book
  void _showReviewAlreadyExistsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Disable dismissal by clicking outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF790AD)
                .withOpacity(0.9), // Pinkish background with opacity
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning, // Warning icon for review exists
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                'You have already reviewed this book. You need to delete your old review to review it again.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey, // Grey background for "Exit"
                ),
                child: const Text(
                  'Exit',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Review {
  final String readerId;
  final String readerName;
  final String readerProfilePhoto;
  final String reviewText;
  final double rating;
  final DateTime createdAt;
  final String bookId;
  final String timeAgo; // Add this line

  Review({
    required this.readerId,
    required this.readerName,
    required this.readerProfilePhoto,
    required this.reviewText,
    required this.rating,
    required this.createdAt,
    required this.bookId,
    required this.timeAgo, // Update this line
  });
}

Future<List<Review>> fetchReviews(String bookId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('reviews')
      .where('bookID', isEqualTo: bookId)
      .get();

  final reviews = <Review>[];
  final String currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? ''; // Get current user ID

  Review? myReview;

  for (var doc in snapshot.docs) {
    final data = doc.data();
    String readerId = data['reader_id'] ?? ''; // Ensure the correct key is used

    // Fetch the reader's details from the readers collection
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('reader')
        .doc(readerId)
        .get();

    final userData = userSnapshot.data() as Map<String, dynamic>?;

    // Change readerName to "You" if it's the current user's review
    String readerName = (readerId == currentUserId)
        ? 'You'
        : (userData?['name'] ??
            'Anonymous'); // Default to 'Anonymous' if no name is available

    DateTime createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    Review review = Review(
      readerId: readerId,
      readerName: readerName,
      readerProfilePhoto: userData?['profilePhoto'] ?? '',
      reviewText: data['reviewText'] ?? 'No review provided',
      rating: (data['rating'] is double)
          ? data['rating']
          : (data['rating'] as int).toDouble(),
      createdAt: createdAt, // Set createdAt for each review
      bookId: bookId, // Set bookId for each review
      timeAgo: timeAgo(createdAt), // Calculate time ago
    );

    // Check if the review belongs to the current user
    if (readerId == currentUserId) {
      myReview = review; // Save current user's review separately
    } else {
      reviews.add(review); // Add others' reviews
    }
  }

  // Sort the reviews by createdAt (newest first)
  reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // If the current user has provided a review, add it at the top
  if (myReview != null) {
    reviews.insert(0, myReview);
  }

  return reviews;
}

String timeAgo(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inSeconds < 1) {
    return 'just now'; // Case for the time difference being less than 1 second
  } else if (difference.inSeconds < 60) {
    return '${difference.inSeconds} second${difference.inSeconds > 1 ? 's' : ''} ago'; // Display seconds
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  } else if (difference.inDays < 365) {
    return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() > 1 ? 's' : ''} ago';
  } else {
    return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
  }
}
