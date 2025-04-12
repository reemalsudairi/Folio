import 'package:flutter/material.dart';
import 'book.dart';
import 'book_card_template.dart';

// Subclass for finished books – inherits shared layout and defines its own menu options
class FinishedBookCard extends BookCardTemplate {
  const FinishedBookCard({
    super.key,
    required super.book,
    required super.userId,
    required super.onMenuSelected,
  });

  // Popup menu options specific to finished books
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
        value: 'Move to Saved',
        child: ListTile(
          leading: Icon(Icons.bookmark, color: Color(0xFF351F1F)),
          title: Text('Move to Saved'),
        ),
      ),
      PopupMenuItem<String>(
        value: 'Remove from Finished',
        child: ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('Remove from Finished'),
        ),
      ),
    ];
  }
}

