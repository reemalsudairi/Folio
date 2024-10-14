import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:folio/screens/Profile/currently_reading_page.dart';
import 'package:folio/screens/Profile/profile.dart';
import 'package:folio/screens/book_details_page.dart';
import 'package:folio/screens/categories_page.dart';
import 'package:folio/screens/settings.dart';
import 'Profile/book.dart';
import 'Profile/clubs_page.dart';
import 'package:http/http.dart' as http;
import 'package:folio/screens/bookclubs_page.dart';
import 'package:folio/screens/createClubPage.dart';

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
  bool _isLoadingBooks = true;

  @override
  void initState() {
    super.initState();
    _setupUserDataListener();
    _fetchCurrentlyReadingBooks(); 
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
            )
          : _selectedIndex == 1
              ? const CategoriesPage()
              : _selectedIndex == 2
                  ?  ClubsPage()
                  : ProfilePage(onEdit: _setupUserDataListener),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFF790AD),
        unselectedItemColor: const Color(0xFFB3B3B3),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 35),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined, size: 35),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined, size: 35),
            label: 'Library',
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
  final bool isLoadingBooks;

  const HomePageContent({
    super.key,
    required this.name,
    required this.profilePhotoUrl,
    required this.booksGoal,
    required this.booksRead,
    required this.currentlyReadingBooks,
    required this.isLoadingBooks,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            const SizedBox(height: 120),
            const Text(
              'Clubs',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 53, 31, 31),
              ),
            ),
            const SizedBox(height: 15),
            _buildClubsSection(),
            const SizedBox(height: 30),
            // Create Club Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateClubPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF790AD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Create a Club',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
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
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 20),
                      itemBuilder: (context, index) {
                        Book book = currentlyReadingBooks[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailsPage(
                                  bookId: book.id,
                                  userId: FirebaseAuth.instance.currentUser?.uid ?? '',
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

  Widget _buildClubsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text(
          'No joined clubs yet',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 53, 31, 31),
          ),
        ),
      ),
    );
  }
}
