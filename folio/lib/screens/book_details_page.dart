import 'package:flutter/material.dart';
import 'package:folio/screens/bookclubs_page.dart';
import 'package:folio/services/google_books_service.dart';
import 'package:html/parser.dart'; // For parsing HTML
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:folio/screens/viewClub.dart';

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

    final details = await _googleBooksService.getBookDetails(widget.bookId); // Fetch book details
    
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

    print('Loading: $_isLoading (After fetching data)'); // Check loading state after
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
            doc.data() as Map<String, dynamic>,
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
          builder: (context) => ViewClub(clubId: club.id), // Navigate to club details
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
                        return const Center(child: CircularProgressIndicator());
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
          const SizedBox(height: 8), // Add some space between the image and text

          // Club name
          Flexible(
            child: Text(
              club.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1, // Limit to one line
              overflow: TextOverflow.ellipsis, // Show ellipsis if name is too long
            ),
          ),
          const SizedBox(height: 4),

          // Member count (smaller font size)
          Flexible(
            child: Text(
                  '${club.memberCount} members', // Correctly displaying the member count
              style: const TextStyle(fontSize: 14, color: Colors.grey), // Smaller text size
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

    if (currentUserId == null || currentUserId.isEmpty) {
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
          if (list == 'finished') {
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
      bool goalAchievedOnce = data?['goalAchievedOnce'] ?? false; // Flag to check if message was shown

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
        _showGoalAchievedDialog();  // Show the goal achieved dialog

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
              color: Color(0xFFF790AD),// Icon color matching the progress bar
              size: 50,
            ),
            const SizedBox(width: 10),
            Text(
              'Goal Achieved!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],  // Matching design colors
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
                color: Colors.brown[600],  // Keeping a consistent color palette
                fontWeight: FontWeight.bold,
                  fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: 1,  // Full progress to signify the goal is met
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
    ? const Center(child: CircularProgressIndicator()) // Show loading indicator if still loading
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
                  bookDetails?['volumeInfo']['imageLinks']?['thumbnail'] ??
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
                                  : '$selectedOption',
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
