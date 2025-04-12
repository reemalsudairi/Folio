import 'package:flutter/material.dart';
import 'book.dart';
import 'book_card_template.dart';

// Subclass for saved books – inherits shared UI and defines saved-specific actions
class SavedBookCard extends BookCardTemplate {
  const SavedBookCard({
    super.key,
    required super.book,
    required super.userId,
    required super.onMenuSelected,
  });

  // Popup menu options for books in the "Saved" list
  @override
  List<PopupMenuEntry<String>> buildMenuOptions() {
    return [
      const PopupMenuItem<String>(
        value: 'Move to Currently Reading',
        child: ListTile(
          leading: Icon(Icons.menu_book, color: Color(0xFF351F1F)),
          title: Text('Move to Currently Reading'),
        ),
      ),
      const PopupMenuItem<String>(
        value: 'Move to Finished',
        child: ListTile(
          leading: Icon(Icons.check_circle, color: Color(0xFF351F1F)),
          title: Text('Move to Finished'),
        ),
      ),
      PopupMenuItem<String>(
        value: 'Remove from Saved',
        child: ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('Remove from Saved'),
        ),
      ),
    ];
  }
}
