import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/Profile/profile.dart'; // Import ProfilePage
import 'package:folio/screens/categories_page.dart'; // Import CategoriesPage
import 'package:folio/screens/edit_profile.dart';
import 'package:folio/screens/settings.dart'; // Import for EditProfilePage

class HomePage extends StatefulWidget {
  const HomePage({super.key, required String userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Tracks the selected tab
  String _name = '';
  String _profilePhotoUrl = '';
  int _booksGoal = 0;
  int _booksRead = 0;

  // List of pages for each tab
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data from Firestore
 void _fetchUserData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDoc = await FirebaseFirestore.instance.collection('reader').doc(user.uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      setState(() {
        _name = userData['name'] ?? '';
        _profilePhotoUrl = userData['profilePhoto'] ?? '';
        _booksGoal = userData['books'] ?? 0;
        _booksRead = userData['booksRead'] ?? 0; // Ensure this matches Firestore fields
        _initializePages();
      });
    }
  }
}


  void _initializePages() {
    _pages = [
      HomeContent(
        name: _name,
        profilePhotoUrl: _profilePhotoUrl,
        booksGoal: _booksGoal,
        booksRead: _booksRead,
        onEdit: _fetchUserData, // Pass the update method
      ),
      const CategoriesPage(),
      const LibraryPage(),
ProfilePage(onEdit: _fetchUserData),    ];
  }

  // Update the index when a tab is selected
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Navigate to EditProfile and get updated data
  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfile(
          userId: FirebaseAuth.instance.currentUser!.uid,
          name: _name,
          profilePhotoUrl: _profilePhotoUrl,
          booksGoal: _booksGoal, bio: '', 
          email: '',
        ),
      ),
    );

    // Check if result is not null and update the profile data
    if (result != null) {
      setState(() {
        _name = result['name'] ?? _name;
        _profilePhotoUrl = result['profilePhoto'] ?? _profilePhotoUrl;
        _booksGoal = result['books'] ?? _booksGoal;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      body: _pages.isNotEmpty ? _pages[_selectedIndex] : Center(child: CircularProgressIndicator()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFF790AD), // Pink color for selected item
        unselectedItemColor: const Color(0xFFB3B3B3), // Grey color for unselected item
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

// Content for the Home tab
class HomeContent extends StatelessWidget {
  final String name;
  final String profilePhotoUrl;
  final int booksGoal;
  final int booksRead;
  final VoidCallback onEdit;

  const HomeContent({
    super.key,
    required this.name,
    required this.profilePhotoUrl,
    required this.booksGoal,
    required this.booksRead,
    required this.onEdit, // Receive onEdit callback
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: const Color(0xFFF8F5F1),
       appBar: PreferredSize(
  preferredSize: const Size(412, 56),
  child: AppBar(
    backgroundColor: const Color(0xFFF8F5F1),
    elevation: 0,
    // Remove the leading back button
    automaticallyImplyLeading: false,
    actions: [
      IconButton(
        icon: const Icon(Icons.notifications_active, color: Color.fromARGB(255, 35, 23, 23), size: 30,),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        },      ),
      IconButton(
        icon: const Icon(Icons.person_2, color: Color.fromARGB(255, 35, 23, 23), size: 30,),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        },
      ),
    ],
  ),
),
body: Padding(
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
                : const AssetImage('assets/images/profile_pic.png') as ImageProvider,
          ),
        ],
      ),
      const SizedBox(height: 20),
      _buildYearlyGoal(),
      const SizedBox(height: 30),
      const Text(
        'Currently Reading',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 53, 31, 31),
        ),
      ),
      const SizedBox(height: 15),
      // Currently Reading section
      _buildCurrentlyReadingSection(),
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
      // Clubs section
      _buildClubsSection(),
    ],
  ),
),
    );
  }

  Widget _buildCurrentlyReadingSection() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F5F1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Center(
      child: Text(
        'No added books yet',
        style: TextStyle(
          fontSize: 16,
          color: Color.fromARGB(255, 53, 31, 31),
        ),
      ),
    ),
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

  // Yearly Goal section
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
}

// Placeholder for the LibraryPage
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Library Page Content',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}