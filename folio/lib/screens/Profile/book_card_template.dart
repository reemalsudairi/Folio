import 'package:flutter/material.dart';
import 'package:folio/screens/book_details_page.dart';
import 'book.dart';

// Abstract class defining the shared layout for all book cards
abstract class BookCardTemplate extends StatelessWidget {
  final Book book;
  final String userId;
  final Function(String option) onMenuSelected;

  const BookCardTemplate({
    super.key,
    required this.book,
    required this.userId,
    required this.onMenuSelected,
  });

  // This abstract method allows each subclass to define its own popup menu
  List<PopupMenuEntry<String>> buildMenuOptions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Tapping the book image navigates to the book details page
            GestureDetector(
              onTap: () {
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
            // Popup menu icon in the top right corner
            Positioned(
              right: 10,
              top: 10,
              child: Builder(
                builder: (context) => GestureDetector(
                  onTap: () {
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    final Offset position = box.localToGlobal(Offset.zero);

                    // Show the custom popup menu
                    showMenu<String>(
                      color: Colors.white,
                      context: context,
                      position: RelativeRect.fromLTRB(position.dx, position.dy + 40, position.dx + 40, 0.0),
                      items: buildMenuOptions(), // Dynamically provided by each subclass
                    ).then((String? result) {
                      if (result != null) {
                        onMenuSelected(result);
                      }
                    });
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(4.0),
                    child: const Icon(
                      Icons.more_vert,
                      color: Color(0xFFF790AD),
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SizedBox(
            width: 120,
            child: Column(
              children: [
                // Display book title
                Text(
                  book.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                // Display book author
                Text(
                  book.author,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
