import 'package:flutter/material.dart';

import 'currently_reading_page.dart';
import 'saved_books_page.dart';
import 'finished_books_page.dart';

class LibraryPage extends StatelessWidget {
  final String userId; // Accept the userId for Firebase operations

  const LibraryPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildGridItem(
              context, Icons.menu_book_sharp, 'Currently Reading', 'currently'),
          _buildGridItem(context, Icons.bookmark_border,  'Saved \n\u00A0\u00A0 \u00A0 \u00A0Private🔒\u00A0\u00A0',
'saved'),
          _buildGridItem(
              context, Icons.check_circle_outline, 'Finished', 'finished'),
        ],
      ),
    );
  }

  // Modify the _buildGridItem to accept the context and route to specific pages
  Widget _buildGridItem(
      BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () {
        if (route == 'currently') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CurrentlyReadingPage(userId: userId),
            ),
          );
        } else if (route == 'saved') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SavedBooksPage(userId: userId),
            ),
          );
        } else if (route == 'finished') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FinishedBooksPage(userId: userId),
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