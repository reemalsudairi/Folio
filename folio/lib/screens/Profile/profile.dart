import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/Profile/clubs_page.dart';
import 'package:folio/screens/Profile/library_page.dart';
import 'package:folio/screens/Profile/reviews_page.dart';
import 'package:folio/screens/edit_profile.dart'; // Import for EditProfilePage
import 'package:folio/screens/settings.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required void Function() onEdit});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0;
  String _name = '';
  String _bio = '';
  String _profilePhotoUrl = '';
  int _booksGoal = 0;
  int _booksRead = 0; // Example for tracking progress
  String _username = '';
  String _email = ''; // Add email variable

  static final List<Widget> _pages = <Widget>[
    const LibraryPage(),
    const ClubsPage(),
    const ReviewsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  void _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;
        final userDoc = await FirebaseFirestore.instance.collection('reader').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            _name = userData['name'] ?? '';
            _bio = userData['bio'] ?? '';
            _profilePhotoUrl = userData['profilePhoto'] ?? '';
            _booksGoal = userData['books'] ?? 0;
            _booksRead = 0; // Example value; replace with actual data if available
            _username = userData['username'] ?? ''; // Fetch username
            _email = userData['email'] ?? ''; // Fetch email
          });
        }
      } else {
        // Handle case when user is not logged in
        print('User is not logged in');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      // Handle error, e.g., show a snackbar or alert
    }
  }

  void _onItemTapped(int index) {
  setState(() {
    if (index < _pages.length) {
      _selectedIndex = index;
    }
  });
}

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfile(
          userId: FirebaseAuth.instance.currentUser!.uid,
          name: _name,
          bio: _bio,
          profilePhotoUrl: _profilePhotoUrl,
          booksGoal: _booksGoal,
          email: _email, // Pass the fetched email
        ),
      ),
    );

    // Check if result is not null and update the profile data
    if (result != null) {
      setState(() {
        _name = result['name'] ?? _name;
        _bio = result['bio'] ?? _bio;
        _profilePhotoUrl = result['profilePhoto'] ?? _profilePhotoUrl;
        _booksGoal = result['books'] ?? _booksGoal;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F1),
      appBar: PreferredSize(
        preferredSize: const Size(412, 56),
        child: AppBar(
          backgroundColor: const Color(0xFFF8F5F1),
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color.fromARGB(255, 35, 23, 23)),
              onPressed: _navigateToEditProfile,
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Color.fromARGB(255, 35, 23, 23)),
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
      body: Container(
        color: const Color(0xFFF8F5F1),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _profilePhotoUrl.isNotEmpty
                  ? NetworkImage(_profilePhotoUrl)
                  : const AssetImage('assets/avatar.png') as ImageProvider,
            ),
            const SizedBox(height: 5),
            Text(
              _name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            Text(
              '@$_username', // Use the username variable here
              style: TextStyle(
                color: const Color.fromARGB(255, 88, 71, 71),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 250,
              child: Text(
                _bio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color.fromARGB(255, 31, 24, 24),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildYearlyGoal(),
            const SizedBox(height: 20),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () => _onItemTapped(0),
                      child: Column(
                        children: [
                          Text(
                            'Library',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedIndex == 0 ? Colors.brown[800] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _onItemTapped(1),
                      child: Column(
                        children: [
                          Text(
                            'Clubs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedIndex == 1 ? Colors.brown[800] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _onItemTapped(2),
                      child: Column(
                        children: [
                          Text(
                            'Reviews',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedIndex == 2 ? Colors.brown[800] : Colors.grey[600],
                            ),
                          ),
                        ],
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
                      left: _selectedIndex * (412 / 3) + 16,
                      top: -1,
                      child: Container(
                        height: 4,
                        width: 100,
                        color: Colors.brown[800],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyGoal() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 30),
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
              Text(
                'Yearly Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
              Text(
                '$_booksRead/$_booksGoal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _booksGoal > 0 ? _booksRead / _booksGoal : 0,
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
