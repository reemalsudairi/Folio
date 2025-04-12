import 'package:flutter/material.dart';
import 'book.dart';
import 'book_card_template.dart';
// Subclass for currently reading books – inherits base layout and provides its own menu
class CurrentlyReadingBookCard extends BookCardTemplate {
  const CurrentlyReadingBookCard({
    super.key,
    required super.book,
    required super.userId,
    required super.onMenuSelected,
  });
  // Popup menu options for books in the "Currently Reading" list
  @override
  List<PopupMenuEntry<String>> buildMenuOptions() {
    return [
      const PopupMenuItem<String>(
        value: 'Move to Finished',
        child: ListTile(
          leading: Icon(Icons.check_circle, color: Color(0xFF351F1F)),
          title: Text('Move to Finished'),
        ),
      ),
      const PopupMenuItem<String>(
        value: 'Move to Saved',
        child: ListTile(
          leading: Icon(Icons.bookmark, color: Color(0xFF351F1F)),
          title: Text('Move to Saved'),
        ),
      ),
      const PopupMenuItem<String>(
        value: 'Remove from Currently Reading',
        child: ListTile(
          leading: Icon(Icons.delete, color: Colors.red),
          title: Text('Remove from Currently Reading'),
        ),
      ),
    ];
  }
}