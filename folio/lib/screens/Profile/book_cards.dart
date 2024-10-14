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
    return GestureDetector(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
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
              Positioned(
                right: -30,
                top: 5,
                child: PopupMenuButton<String>(
                  onSelected: (String result) {
                    onMenuSelected(result);
                  },
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xFFF790AD),
                    size: 20,
                  ),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Move to Currently Reading',
                      child: ListTile(
                        leading: Icon(Icons.menu_book, color: Colors.brown),
                        title: Text('Move to Currently Reading'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Move to Finished',
                      child: ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.brown),
                        title: Text('Move to Finished'),
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
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
                const SizedBox(height: 4),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

