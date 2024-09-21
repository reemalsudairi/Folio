import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GoogleBooksService {
  final String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  final String apiKey = 'AIzaSyC0cNRGm7PrHIKVNtLMuAu4707hz4Yi0h0';

  Future<Map<String, dynamic>> getBookDetails(String bookId) async {
    final Uri url = Uri.parse('$_baseUrl/$bookId?key=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load book details');
    }
  }

  Future<List<dynamic>> searchBooks(String query, {bool isCategory = false}) async {
    List<dynamic> allBooks = [];
    String queryString = isCategory ? 'subject:$query' : query;

    List<dynamic> englishBooks = await _fetchBooks(queryString, 'en');
    List<dynamic> arabicBooks = await _fetchBooks(queryString, 'ar');

    allBooks.addAll(englishBooks);
    allBooks.addAll(arabicBooks);

    return _processBooks(allBooks, query);
  }

  Future<List<dynamic>> _fetchBooks(String query, String language) async {
    List<dynamic> books = [];
    int maxResultsPerRequest = 40;
    int totalResultsToFetch = 100;
    int startIndex = 0;

    while (books.length < totalResultsToFetch) {
      final Uri url = Uri.parse(
          '$_baseUrl?q=$query&langRestrict=$language&orderBy=newest&startIndex=$startIndex&maxResults=$maxResultsPerRequest&key=$apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> fetchedBooks = data['items'] ?? [];

        if (fetchedBooks.isEmpty) break;

        books.addAll(fetchedBooks);
        startIndex += maxResultsPerRequest;
      } else {
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    }

    return books;
  }

  List<dynamic> _processBooks(List<dynamic> books, String searchTerm) {
    final Set<String> seenBookSignatures = {};
    final List<dynamic> exactMatches = [];
    final List<dynamic> relatedBooks = [];

    String normalizedSearchTerm = searchTerm.toLowerCase();

    for (var book in books) {
      String title = book['volumeInfo']['title']?.toLowerCase() ?? '';
      String authors = (book['volumeInfo']['authors']?.join(', ') ?? '').toLowerCase();
      String? thumbnail = book['volumeInfo']['imageLinks']?['thumbnail'];

      
      String maturityRating = book['volumeInfo']['maturityRating'] ?? 'NOT_MATURE';
      String description = book['volumeInfo']['description']?.toLowerCase() ?? '';
      List<dynamic> categories = book['volumeInfo']['categories'] ?? [];

      List<String> excludedKeywords = [
        'erotic', 'lgbt', 'gay', 'adult', 'explicit', 'israel', 'judaism', 'jewish', 'zionism'
      ];

      if (maturityRating == 'MATURE' || _containsExcludedKeyword(description, categories, excludedKeywords)) {
        continue;
      }

      if (thumbnail == null) {
        continue;
      }

      String bookSignature = _createBookSignature(title, authors);

      if (seenBookSignatures.contains(bookSignature)) {
        continue;
      }

      if (title == normalizedSearchTerm) {
        exactMatches.add(book);
      } else {
        relatedBooks.add(book);
      }

      seenBookSignatures.add(bookSignature);
    }

    return [...exactMatches, ...relatedBooks];
  }

  String _createBookSignature(String title, String authors) {
    return '$title|$authors';
  }

  bool _containsExcludedKeyword(String description, List<dynamic> categories, List<String> excludedKeywords) {
    for (String keyword in excludedKeywords) {
      if (description.contains(keyword)) {
        return true;
      }
      for (String category in categories) {
        if (category.toLowerCase().contains(keyword)) {
          return true;
        }
      }
    }
    return false;
  }

  List<Map<String, dynamic>> getBookCategories() {
    return [
      {'category': 'Fiction', 'icon': Icons.book},
      {'category': 'Science', 'icon': Icons.science},
      {'category': 'History', 'icon': Icons.history_edu},
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
      {'category': 'Self-help', 'icon': Icons.self_improvement},
      {'category': 'Mystery', 'icon': Icons.search},
      {'category': 'Fantasy', 'icon': Icons.cloud},
    ];
  }
}
