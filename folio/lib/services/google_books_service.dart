import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GoogleBooksService {
  final String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  final String apiKey =
      'AIzaSyC0cNRGm7PrHIKVNtLMuAu4707hz4Yi0h0'; 


      Future<Map<String, dynamic>> getBookDetails(String bookId) async {
    final Uri url = Uri.parse('$_baseUrl/$bookId?key=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load book details');
    }
  }

  // Fetch books by query (subject) or general search term, ordered by newest
  Future<List<dynamic>> searchBooks(String query,
      {bool isCategory = false, String language = 'en'}) async {
    String queryString = isCategory ? 'subject:$query' : query;

    List<dynamic> allBooks = [];
    int maxResultsPerRequest = 40;
    int totalResultsToFetch = 100;
    int startIndex = 0;

    // Fetch books in batches until reaching totalResultsToFetch or no more books are available
    while (allBooks.length < totalResultsToFetch) {
      final Uri url = Uri.parse(
          '$_baseUrl?q=$queryString&langRestrict=$language&orderBy=newest&startIndex=$startIndex&maxResults=$maxResultsPerRequest&key=$apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> fetchedBooks = data['items'] ?? [];

        if (fetchedBooks.isEmpty) break;

        allBooks.addAll(fetchedBooks);
        startIndex += maxResultsPerRequest;
      } else {
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    }

    // Process books: prioritize exact matches, remove duplicates based on title and authors
    return _processBooks(allBooks, query);
  }

  // Process books to prioritize exact matches and remove duplicates based on title and authors
  List<dynamic> _processBooks(List<dynamic> books, String searchTerm) {
    final Set<String> seenBookSignatures =
        {}; // Track book uniqueness by title and authors
    final List<dynamic> exactMatches = [];
    final List<dynamic> relatedBooks = [];

    String normalizedSearchTerm = searchTerm.toLowerCase();

    for (var book in books) {
      String title = book['volumeInfo']['title']?.toLowerCase() ?? '';
      String authors =
          (book['volumeInfo']['authors']?.join(', ') ?? '').toLowerCase();

      // Normalize the data for duplicate detection
      String bookSignature = _createBookSignature(title, authors);

      // Skip if the book is a duplicate (same title and authors)
      if (seenBookSignatures.contains(bookSignature)) {
        continue;
      }

      // Exact match: prioritize books where the title exactly matches the search term
      if (title == normalizedSearchTerm) {
        exactMatches.add(book);
      } else {
        relatedBooks.add(book);
      }

      // Track book by signature to avoid future duplicates
      seenBookSignatures.add(bookSignature);
    }

    // Combine exact matches followed by related books
    return [...exactMatches, ...relatedBooks];
  }

  // Create a unique signature for each book based on title and authors
  String _createBookSignature(String title, String authors) {
    return '$title|$authors';
  }

  // Return predefined categories with icons
  List<Map<String, dynamic>> getBookCategories() {
    return [
      {'category': 'Fiction', 'icon': Icons.book},
      {'category': 'Science', 'icon': Icons.science},
      {'category': 'History', 'icon': Icons.history},
      {'category': 'Technology', 'icon': Icons.computer},
      {'category': 'Art', 'icon': Icons.brush},
      {'category': 'Philosophy', 'icon': Icons.psychology},
      {'category': 'Business', 'icon': Icons.business},
      {'category': 'Health', 'icon': Icons.health_and_safety},
      {'category': 'Education', 'icon': Icons.school},
      {'category': 'Biography', 'icon': Icons.person},
      {'category': 'Travel', 'icon': Icons.flight},
      {'category': 'Music', 'icon': Icons.music_note},
      {'category': 'Sports', 'icon': Icons.sports_soccer},
      {'category': 'Nature', 'icon': Icons.park},
      {'category': 'Classics', 'icon': Icons.class_},
      {'category': 'Interesting', 'icon': Icons.star},
      {'category': 'Self-help', 'icon': Icons.self_improvement},
      {'category': 'Mystery', 'icon': Icons.search},
      {'category': 'Fantasy', 'icon': Icons.cloud},
    ];
  }
}
