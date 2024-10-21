import 'package:flutter/material.dart';
import 'package:folio/screens/book_details_page.dart';

import 'book.dart';


class SavedBookCard extends StatelessWidget {
  final Book book;
  final String userId;
  final Function(String option) onMenuSelected;


  const SavedBookCard({
    super.key,
    required this.book,
    required this.userId,
    required this.onMenuSelected,
  });


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () {
                // Navigate to book details page when the book is tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailsPage(
                      bookId: book.id,
                      userId: userId,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  book.thumbnailUrl,
                  height: 180,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    width: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Builder(
                builder: (context) => GestureDetector(
                  onTap: () {
                    // Get the position of the white circle relative to the screen
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    final Offset position = box.localToGlobal(Offset.zero);


                    showMenu<String>(
                      color: Colors.white,
                      context: context,
                      position: RelativeRect.fromLTRB(
                        position.dx,   // Use the x-position of the white circle
                        position.dy + 40, // Adjust y-position to be slightly below the circle
                        position.dx + 40, // Adjust width for the right side of the menu
                        0.0,             // Bottom position can be 0, as it's not needed
                      ),
                      items: <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'Move to Currently Reading',
                          child: ListTile(
                            leading: Icon(Icons.menu_book, color: Color(0xFF351F1F)),
                            title: Text(
                              'Move to Currently Reading',
                              style: TextStyle(color: Color(0xFF351F1F)),
                            ),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Move to Finished',
                          child: ListTile(
                            leading: Icon(Icons.check_circle, color: Color(0xFF351F1F)),
                            title: Text(
                              'Move to Finished',
                              style: TextStyle(color: Color(0xFF351F1F)),
                            ),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'Remove from Saved',
                          child: ListTile(
                            leading: const Icon(Icons.delete, color: Colors.red),
                            title: const Text(
                              'Remove from Saved',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ).then((String? result) {
                      if (result != null) {
                        onMenuSelected(result);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white, // White background for the circle
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0), // Padding around the icon
                      child: const Icon(
                        Icons.more_vert,
                        color: Color(0xFFF790AD), // Same pink color as before
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // Added spacing for better layout
        Expanded(
          child: SizedBox(
            width: 120,
            child: Column(
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Text(
                  book.author,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}