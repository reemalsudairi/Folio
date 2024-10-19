import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/Profile/currently_reading_page.dart';
import 'package:folio/screens/Profile/profile.dart';
import 'package:folio/screens/book_details_page.dart';
import 'package:folio/screens/bookclubs_page.dart';
import 'package:folio/screens/categories_page.dart';
import 'package:folio/screens/extendedclubs.dart';
import 'package:folio/screens/settings.dart';
import 'package:folio/screens/viewClub.dart';
import 'package:http/http.dart' as http;

import 'Profile/book.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.userId});

  final String userId;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _name = '';
  String _profilePhotoUrl = '';
  int _booksGoal = 0;
  int _booksRead = 0;
  List<Book> currentlyReadingBooks = [];
  List<Club> myClubs = [];
  List<Club> joinedClubs = [];
  bool _isLoadingBooks = true;
  bool _isLoadingClubs = true;
  @override
  void initState() {
    super.initState();
    _setupUserDataListener();
    _fetchCurrentlyReadingBooks();
    _fetchClubs();
  }

  Future<void> _setupUserDataListener() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      FirebaseFirestore.instance
          .collection('reader')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final userData = snapshot.data();
          setState(() {
            _name = userData?['name'] ?? '';
            _profilePhotoUrl = userData?['profilePhoto'] ?? '';
            _booksGoal = userData?['books'] ?? 0;
            _booksRead = userData?['booksRead'] ?? 0;
          });
        }
      });
    }
  }

  Future<void> _fetchCurrentlyReadingBooks() async {
    final user = FirebaseAuth.instance.currentUser;

    // Force Firebase to refresh user data in case of cache issues
    await user?.reload();

    if (user == null) return;

    try {
      CollectionReference booksRef = FirebaseFirestore.instance
          .collection('reader')
          .doc(user.uid)
          .collection('currently reading');

      booksRef.snapshots().listen((snapshot) async {
        List<Book> books = [];
        for (var doc in snapshot.docs) {
          var bookId = doc['bookID'];
          Book book = await _fetchBookFromGoogleAPI(bookId);
          books.add(book);
        }

        setState(() {
          currentlyReadingBooks = books;
          _isLoadingBooks = false;
        });
      });
    } catch (error) {
      print('Error fetching currently reading books: $error');
      setState(() {
        _isLoadingBooks = false;
      });
    }
  }

  Future<Book> _fetchBookFromGoogleAPI(String bookId) async {
    String url = 'https://www.googleapis.com/books/v1/volumes/$bookId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return Book.fromGoogleBooksAPI(data);
    } else {
      throw Exception('Failed to load book data');
    }
  }

  Future<void> _fetchClubs() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    if (userId.isEmpty) {
      print('User is not logged in.');
      return;
    }

    try {
      // Fetch clubs the user owns
      FirebaseFirestore.instance
          .collection('clubs')
          .where('ownerID', isEqualTo: userId)
          .snapshots()
          .listen((QuerySnapshot myClubsSnapshot) async {
        List<Club> tempMyClubs = [];

        for (var doc in myClubsSnapshot.docs) {
          int memberCount = await fetchMemberCount(doc.id);
          tempMyClubs.add(Club.fromMap(
              doc.data() as Map<String, dynamic>, doc.id, memberCount));
        }

        // Update the state for myClubs
        setState(() {
          myClubs = tempMyClubs;
        });
      });

      // Fetch clubs the user has joined but doesn't own
      FirebaseFirestore.instance
          .collection('clubs')
          .snapshots()
          .listen((QuerySnapshot joinedClubsSnapshot) async {
        List<Club> tempJoinedClubs = [];

        for (var doc in joinedClubsSnapshot.docs) {
          var clubData = doc.data() as Map<String, dynamic>?;

          if (clubData != null && clubData.containsKey('ownerID')) {
            DocumentSnapshot memberSnapshot = await FirebaseFirestore.instance
                .collection('clubs')
                .doc(doc.id)
                .collection('members')
                .doc(userId)
                .get();

            if (memberSnapshot.exists && clubData['ownerID'] != userId) {
              int memberCount = await fetchMemberCount(doc.id);
              tempJoinedClubs.add(Club.fromMap(clubData, doc.id, memberCount));
            }
          }
        }

        setState(() {
          joinedClubs = tempJoinedClubs;
          _isLoadingClubs = false;
        });
      });
    } catch (e) {
      print('Error fetching clubs: $e');
      setState(() {
        _isLoadingClubs = false;
      });
    }
  }

  Future<int> fetchMemberCount(String clubId) async {
    try {
    // Get the members subcollection snapshot
    QuerySnapshot membersSnapshot = await FirebaseFirestore.instance
        .collection('clubs')
        .doc(clubId)
        .collection('members')
        .get();

    // If the members collection is empty, return 0 to indicate no members beyond the owner.
    if (membersSnapshot.size == 0) {
      return 1;
    }

    // Otherwise, return the size of the members collection.
    return membersSnapshot.size;
  } catch (e) {
    print('Error fetching member count for club $clubId: $e');
    return 1; // Default to 1 if an error occurs.
  } // Always exceed the actual member size by 1
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
      body: _selectedIndex == 0
          ? HomePageContent(
              name: _name,
              profilePhotoUrl: _profilePhotoUrl,
              booksGoal: _booksGoal,
              booksRead: _booksRead,
              currentlyReadingBooks: currentlyReadingBooks,
              isLoadingBooks: _isLoadingBooks,
              myClubs: myClubs,
              joinedClubs: joinedClubs,
              isLoadingClubs: _isLoadingClubs,
            )
          : _selectedIndex == 1
              ? const CategoriesPage()
              : _selectedIndex == 2
                  ? ClubsBody()
                  : ProfilePage(onEdit: _setupUserDataListener),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFF790AD),
        unselectedItemColor: const Color(0xFFB3B3B3),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 35),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined, size: 35),
            label: 'Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.diversity_3_outlined, size: 35),
            label: 'Clubs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined, size: 35),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  final String name;
  final String profilePhotoUrl;
  final int booksGoal;
  final int booksRead;
  final List<Book> currentlyReadingBooks;
  final List<Club> myClubs;
  final List<Club> joinedClubs;
  final bool isLoadingBooks;
  final bool isLoadingClubs;

  const HomePageContent({
    super.key,
    required this.name,
    required this.profilePhotoUrl,
    required this.booksGoal,
    required this.booksRead,
    required this.currentlyReadingBooks,
    required this.myClubs,
    required this.joinedClubs,
    required this.isLoadingBooks,
    required this.isLoadingClubs,
  });

  @override
  Widget build(BuildContext context) {
    List<Club> allClubs = [...myClubs, ...joinedClubs];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(412, 56),
        child: AppBar(
          backgroundColor: const Color(0xFFF8F8F3), // Updated AppBar color
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IgnorePointer(
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_active,
                  color: Color.fromARGB(255, 35, 23, 23),
                  size: 30,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  );
                },
              ),
            ),
            IgnorePointer(
              child: IconButton(
                icon: const Icon(
                  Icons.person_search_rounded,
                  color: Color.fromARGB(255, 35, 23, 23),
                  size: 30,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  );
                },
              ),
            )
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFFF8F8F3), // Updated background color
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Good Day,\n$name!',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 53, 31, 31),
                      ),
                    ),
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: profilePhotoUrl.isNotEmpty
                          ? NetworkImage(profilePhotoUrl)
                          : const AssetImage('assets/images/profile_pic.png')
                              as ImageProvider,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildYearlyGoal(),
                const SizedBox(height: 30),
                _buildCurrentlyReadingSection(context),
                const SizedBox(height: 30),
                _buildClubsSection(context, allClubs),
                const SizedBox(height: 30),
                // Create Club Button
                // SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton(
                //     onPressed: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //             builder: (context) => const CreateClubPage()),
                //       );
                //     },
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: const Color(0xFFF790AD),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       padding: const EdgeInsets.symmetric(vertical: 16),
                //     ),
                //     child: const Text(
                //       'Create a Club',
                //       style: TextStyle(
                //         fontSize: 18,
                //         fontWeight: FontWeight.bold,
                //         color: Colors.white,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearlyGoal() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Yearly Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 53, 31, 31),
                ),
              ),
              Text(
                '$booksRead/$booksGoal',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 53, 31, 31),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: booksGoal > 0 ? booksRead / booksGoal : 0,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation(Color(0xFFF790AD)),
            minHeight: 13,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentlyReadingSection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Currently Reading',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 53, 31, 31),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CurrentlyReadingPage(
                      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
                  ),
                );
              },
              child: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
        const SizedBox(height: 15),
        isLoadingBooks
            ? const Center(child: CircularProgressIndicator())
            : currentlyReadingBooks.isEmpty
                ? const Center(
                    child: Text(
                      'No books in your currently reading list.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: currentlyReadingBooks.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 20),
                      itemBuilder: (context, index) {
                        Book book = currentlyReadingBooks[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailsPage(
                                  bookId: book.id,
                                  userId:
                                      FirebaseAuth.instance.currentUser?.uid ??
                                          '',
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              book.thumbnailUrl,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 40),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildClubsSection(BuildContext context, List<Club> allClubs) {
    return Container(
      // padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Clubs',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 53, 31, 31),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClubPage(),
                    ),
                  );
                },
                child: const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFF351F1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 10),
          isLoadingClubs
              ? const Center(child: CircularProgressIndicator())
              : allClubs.isEmpty
                  ? const Center(
                      child: Text(
                        'No clubs yet. Join or create one!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : SizedBox(
                      height: 304, // Adjust height to accommodate club cards
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.hardEdge,
                        child: Row(
                          children: allClubs
                              .take(5) // Display only the first 5 clubs
                              .map((club) => _buildClubCard(context, club))
                              .toList(),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildClubCard(BuildContext context, Club club) {
     return GestureDetector(
      // Wrap with GestureDetector
      onTap: () {
        // Navigate to ViewClub page and pass the club ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewClub(
                clubId: club.id), // Replace with your actual ViewClub widget
          ),
        );
      },
    child: Container(
      width: 200, // Set a fixed width to ensure consistent card sizes
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
                    height: 140,
                    width: double.infinity,
                    child: Image.network(
                      club.picture,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 140,
                          width: double.infinity,
                          color: Colors.red,
                          child: Icon(Icons.error, color: Colors.white),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                )
              : Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.withOpacity(0.2),
                    image: DecorationImage(
                      image: AssetImage('assets/images/clubs.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
          const SizedBox(height: 10),
          Text(
            club.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 53, 31, 31),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${club.memberCount} members',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
    );
  }
}
