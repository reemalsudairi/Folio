import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/OtherProfile/memebrClubs.dart';
import 'package:folio/screens/OtherProfile/otherEditProfile.dart'; // Import for OtherEditProfile
import 'package:folio/screens/OtherProfile/otherslibrary.dart';
import 'package:folio/screens/Profile/clubs_page.dart';
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
  

  // Remove the static keyword and initialize _pages as an instance variable
  List<Widget> _pages = [];

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

          // Initialize _pages after fetching user profile
       _pages = [
  OtherLibraryPage(
    memberId: widget.memberId,
    username: _username,
  ),
  Memebrclubs(userId:widget.memberId),
  ReviewsPage(
    readerId: widget.memberId,
    currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '', // Pass the correct userId
  ),
];

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
      title: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reader')
            .doc(widget.memberId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Text('@username', style: TextStyle(fontSize: 20));
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final username = userData['username'] ?? 'username';
          return Text(
            '@$username',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF351F1F),
            ),
          );
        },
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFFF8F8F3),
      actions: [
        if (currentUserId == widget.memberId)
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
                    username: _username,
                  ),
                ),
              );
            },
          ),
      ],
    ),
    body: StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reader')
          .doc(widget.memberId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.data!.exists) {
          return const Center(child: Text('Error loading profile'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final name = userData['name'] ?? '';
        final bio = userData['bio'] ?? '';
        final profilePhotoUrl = userData['profilePhoto'] ?? '';
        final username = userData['username'] ?? 'username';
        final booksGoal = userData['books'] ?? 0;
        final booksRead = userData['booksRead'] ?? 0;

        return SingleChildScrollView(
          child: Container(
            color: const Color(0xFFF8F8F3),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: profilePhotoUrl.isNotEmpty
                      ? NetworkImage(profilePhotoUrl)
                      : const AssetImage('assets/images/profile_pic.png') as ImageProvider,
                ),
                const SizedBox(height: 15),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                ),
                Text(
                  '@$username',
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
                    bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 31, 24, 24),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildYearlyGoal(booksRead, booksGoal),
                const SizedBox(height: 30),
                
                // Navigation Bar
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
                        ),
                      ],
                    ),
                    Container(
                      height: 2,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ],
                ),
                
                // Pages Content
                Container(
                  height: MediaQuery.of(context).size.height * 0.5, // Adjust the height
                  child: _pages.isNotEmpty
                      ? _pages[_selectedIndex]
                      : Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildYearlyGoal(int booksRead, int booksGoal) {
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
              '$booksRead/$booksGoal',
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
      _calculateTextWidth('Library'),
      _calculateTextWidth('Clubs'),
      _calculateTextWidth('Reviews'),
    ];

    // Calculate the total width occupied by the words
    double totalWordsWidth = wordWidths.reduce((a, b) => a + b);
    // Calculate the space left to distribute between the words (padding)
    double spaceBetweenWords = (screenWidth - totalWordsWidth) / 3;

    // Position based on index (for left margin)
    double position = spaceBetweenWords / 2;
    for (int i = 0; i < index; i++) {
      position += wordWidths[i] + spaceBetweenWords;
    }

    // Return middle of the word
    return position + (wordWidths[index] / 2);
  }
}