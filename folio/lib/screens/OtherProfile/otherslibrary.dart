import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:folio/screens/Profile/currently_reading_page.dart';
import 'package:folio/screens/Profile/finished_books_page.dart';
import 'package:folio/screens/Profile/saved_books_page.dart';

import 'othercurrentlyreading.dart'; // For other user's currently reading page
import 'otherfinished.dart'; // For other user's finished books page

class OtherLibraryPage extends StatelessWidget {
  final String memberId; // Accept the memberId for Firebase operations
  final String username; // Accept the username for displaying in titles

  const OtherLibraryPage({super.key, required this.memberId, required this.username});

  @override
  Widget build(BuildContext context) {
    // Get the current logged-in user ID
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return SingleChildScrollView(
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildGridItem(
            context,
            Icons.menu_book_sharp,
            'Currently Reading',
            'currently',
            currentUserId == memberId,
          ),
        
          // Show Saved section if this is the logged-in user's profile
          if (currentUserId == memberId)
            _buildGridItem(
              context,
              Icons.bookmark_border, 
              'Saved \n\u00A0\u00A0 \u00A0 \u00A0Private🔒\u00A0\u00A0',
              'saved',
              true, // It's the user's own profile
            ),
              _buildGridItem(
            context,
            Icons.check_circle_outline,
            'Finished',
            'finished',
            currentUserId == memberId,
          ),
        ],
      ),
    );
  }

  // Modify the _buildGridItem to accept the context and route to specific pages based on whether it's own profile or other profile
  Widget _buildGridItem(
      BuildContext context, IconData icon, String label, String route, bool isOwnProfile) {
    return GestureDetector(
      onTap: () {
        if (route == 'currently') {
          if (isOwnProfile) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CurrentlyReadingPage(userId: memberId),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtherProfileCurrentlyReadingPage(
                  memberId: memberId,
                  username: username,
                ),
              ),
            );
          }
        } else if (route == 'finished') {
          if (isOwnProfile) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FinishedBooksPage(userId: memberId),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtherProfileFinishedBooksPage(
                  memberId: memberId,
                  username: username,
                ),
              ),
            );
          }
        } else if (route == 'saved' && isOwnProfile) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SavedBooksPage(userId: memberId),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(20),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.brown[800]),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
