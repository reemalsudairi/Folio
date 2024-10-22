import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/OtherProfile/otherEditProfile.dart'; // Import for OtherEditProfile
import 'package:folio/screens/Profile/clubs_page.dart';
import 'package:folio/screens/Profile/library_page.dart';
import 'package:folio/screens/Profile/reviews_page.dart';

class OtherProfile extends StatefulWidget {
  final String memberId;
  const OtherProfile({Key? key, required this.memberId}) : super(key: key);

  @override
  _OtherProfileState createState() => _OtherProfileState();
}

class _OtherProfileState extends State<OtherProfile> {
  String _name = '';
  String _bio = '';
  String _profilePhotoUrl = '';
  String _email = '';
  int _booksGoal = 0; 
  int _booksRead = 0; 
  String _username = '';
  bool _isLoading = true; 
  int _selectedIndex = 0; // Track selected index for navigation
  

  static final List<Widget> _pages = <Widget>[
    const LibraryPage(userId: ''), // Pass memberId if necessary
    ClubsPage(),
   ReviewsPage(
    readerId: '', // Pass the correct userId
  ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  void _fetchUserProfile() async {
    final userId = widget.memberId;
    print('Fetching user profile for ID: $userId');
    setState(() {
      _isLoading = true; // Set loading state to true
    });

    FirebaseFirestore.instance
        .collection('reader')
        .doc(userId)
        .get()
        .then((userDoc) {
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _name = userData['name'] ?? '';
          _bio = userData['bio'] ?? '';
          _profilePhotoUrl = userData['profilePhoto'] ?? '';
          _email = userData['email'] ?? '';
          _booksGoal = userData['books'] ?? 0; 
          _booksRead = userData['booksRead'] ?? 0; 
          _username = userData['username'] ?? '';
        });
        print('User profile fetched: $_name, $_username');
      } else {
        print('User document does not exist.');
      }
    }).whenComplete(() {
      setState(() {
        _isLoading = false; // Set loading state to false after fetching
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    print('Current User ID: $currentUserId');
    print('Profile Member ID: ${widget.memberId}');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Other Profile'),
        backgroundColor: const Color(0xFFF8F8F3),
        actions: [
          if (currentUserId == widget.memberId) // Ensure this condition is valid
            IconButton(
              icon: Icon(Icons.edit, color: Colors.brown[800]),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtherEditProfile(
                      userId: widget.memberId,
                      name: _name,
                      bio: _bio,
                      profilePhotoUrl: _profilePhotoUrl,
                      booksGoal: _booksGoal,
                      email: _email,
                    ),
                  ),
                ).then((_) {
                  // Refresh profile data after coming back from edit page
                  _fetchUserProfile();
                });
              },
            ),
        ],
      ),
      body: _isLoading // Show loading indicator if loading
          ? Center(child: CircularProgressIndicator())
          : Container(
              color: const Color(0xFFF8F8F3),
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profilePhotoUrl.isNotEmpty
                        ? NetworkImage(_profilePhotoUrl)
                        : const AssetImage('assets/images/profile_pic.png') as ImageProvider,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                  Text(
                    '@$_username',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 88, 71, 71),
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
                        fontSize: 16,
                        color: Color.fromARGB(255, 31, 24, 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildYearlyGoal(),
                  const SizedBox(height: 30),
                  // New Navigation Bar
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                            onPressed: () => _onItemTapped(0),
                            child: Text(
                              'Library',
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
                            // Added more spacing for the buttons
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
                            left: _getWordMiddlePosition(
                                        _selectedIndex,
                                        MediaQuery.of(context).size.width) - 
                                    _calculateTextWidth(
                                            _getSelectedText()) / 2, // Position in the middle of the selected word
                            top: -1,
                            child: Container(
                              height: 4,
                              width: _calculateTextWidth(_getSelectedText()),
                              color: Colors.brown[800],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Expanded(
                    child: _pages[_selectedIndex],
                  ),
                ],
              ),
            ),
    );
  }

  // Yearly Goal section with booksRead and booksGoal
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
      crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start
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


  String _getSelectedText() {
    switch (_selectedIndex) {
      case 0:
        return 'Library';
      case 1:
        return 'Clubs';
      case 2:
        return 'Reviews';
      default:
        return '';
    }
  }

  double _getWordMiddlePosition(int index, double screenWidth) {
    switch (index) {
      case 0:
        return screenWidth * 0.20; // Adjust position for 'Library'
      case 1:
        return screenWidth * 0.50;  // Adjust position for 'Clubs'
      case 2:
        return screenWidth * 0.80; // Adjust position for 'Reviews'
      default:
        return 0;
    }
  }

  double _calculateTextWidth(String text) {
    final textStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.brown,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }
}
