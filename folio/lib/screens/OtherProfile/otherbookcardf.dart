import 'package:flutter/material.dart';
import 'package:folio/screens/Profile/book.dart';
import 'package:folio/screens/book_details_page.dart';

class ReadOnlyFinishedBookCard extends StatelessWidget {
  final Book book;

  const ReadOnlyFinishedBookCard({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            // Navigate to book details page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailsPage(
                  bookId: book.id,
                  userId: '', // Pass the correct user ID if needed
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
        const SizedBox(height: 8),
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
