import 'dart:convert';
<<<<<<< Updated upstream

=======
import 'package:flutter/material.dart';
>>>>>>> Stashed changes
import 'package:http/http.dart' as http;

class GoogleBooksService {
  final String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
<<<<<<< Updated upstream
final String apiKey1 = 'AIzaSyDEtX1xEizreYZkdFQtltWBm3z6KViocbI';
=======
  final String apiKey1 = 'AIzaSyDEtX1xEizreYZkdFQtltWBm3z6KViocbI';
>>>>>>> Stashed changes
  final String apiKey2 = 'AIzaSyA_g6ljLsAnGo_mM6ufkasr_KESLvSWils';

  // Fetch the top 30 best-selling books (or highly relevant books)
  Future<List<dynamic>> fetchBestSellingBooks() async {
    List<dynamic> bestSellingBooks = [];
    int maxResults = 30; // Fetch the top 30 books

    final Uri url = Uri.parse(
        '$_baseUrl?q=best+seller&orderBy=relevance&maxResults=$maxResults&key=$apiKey1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      bestSellingBooks = data['items'] ?? [];
    } else {
      throw Exception('Failed to load best-selling books');
    }

    return bestSellingBooks;
  }

  // Get details of a specific book by its ID
  Future<Map<String, dynamic>> getBookDetails(String bookId) async {
    final Uri url = Uri.parse('$_baseUrl/$bookId?key=$apiKey1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load book details');
    }
  }

  // Search books based on query; fetch books in both English and Arabic
  Future<List<dynamic>> searchBooks(String query,
      {bool isCategory = false}) async {
    List<dynamic> allBooks = [];
    String queryString = isCategory ? 'subject:$query' : query;

    // Fetch books in both English and Arabic
    List<dynamic> englishBooks = await _fetchBooks(queryString, 'en');
    List<dynamic> arabicBooks = await _fetchBooks(queryString, 'ar');

    allBooks.addAll(englishBooks);
    allBooks.addAll(arabicBooks);

    // Process and return the books
    return _processBooks(allBooks, query);
  }

 // Fetch books from the API in a specific language with API key fallback
Future<List<dynamic>> _fetchBooks(String query, String language) async {
  List<dynamic> books = [];
  int maxResultsPerRequest = 40;
  int totalResultsToFetch = 100;
  int startIndex = 0;
  String currentKey = apiKey1; // Start with the first key

  while (books.length < totalResultsToFetch) {
    try {
      final Uri url = Uri.parse(
          '$_baseUrl?q=$query&langRestrict=$language&orderBy=newest&startIndex=$startIndex&maxResults=$maxResultsPerRequest&key=$currentKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> fetchedBooks = data['items'] ?? [];

        if (fetchedBooks.isEmpty) break;

        books.addAll(fetchedBooks);
        startIndex += maxResultsPerRequest;
      } else if (response.statusCode == 403) {
        // Switch to the second API key if quota is exceeded
        currentKey = currentKey == apiKey1 ? apiKey2 : apiKey1;
        continue; // Retry the request with the new key
      } else {
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching books: $e');
    }
  }

  return books;
}

  // Process books and filter them based on excluded keywords, duplicates, etc.
  List<dynamic> _processBooks(List<dynamic> books, String searchTerm) {
    final Set<String> seenBookSignatures = {};
    final List<dynamic> exactMatches = [];
    final List<dynamic> relatedBooks = [];

    String normalizedSearchTerm = searchTerm.toLowerCase();

    for (var book in books) {
      String title = book['volumeInfo']['title']?.toLowerCase() ?? '';
      String authors =
          (book['volumeInfo']['authors']?.join(', ') ?? '').toLowerCase();
      String? thumbnail = book['volumeInfo']['imageLinks']?['thumbnail'];

      String maturityRating =
          book['volumeInfo']['maturityRating'] ?? 'NOT_MATURE';
      String description =
          book['volumeInfo']['description']?.toLowerCase() ?? '';
      List<dynamic> categories = book['volumeInfo']['categories'] ?? [];

      // Exclude books with explicit content or certain keywords
     List<String> excludedKeywords = [
          'erotic',
          'lgbt',
          'gay',
          'adult',
          'explicit',
          'israel',
          'judaism',
          'jewish',
          'zionism',
          'porn',
          'sex',
          'xxx'
        ];

      if (maturityRating == 'MATURE' ||
          containsExcludedKeyword(description, categories, excludedKeywords)) {
        continue;
      }

      if (thumbnail == null) continue; // Skip books without thumbnails

      String bookSignature = _createBookSignature(title, authors);

      if (seenBookSignatures.contains(bookSignature))
        continue; // Skip duplicates

      // Add to exact matches or related books
      if (title == normalizedSearchTerm) {
        exactMatches.add(book);
      } else {
        relatedBooks.add(book);
      }

      seenBookSignatures.add(bookSignature);
    }

    return [...exactMatches, ...relatedBooks];
  }

  // Generate a signature to identify unique books (to avoid duplicates)
  String _createBookSignature(String title, String authors) {
    return '$title|$authors';
  }

  // Check if the book description or categories contain excluded keywords
  bool containsExcludedKeyword(String description, List<dynamic> categories,
      List<String> excludedKeywords) {
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

  // Get predefined categories for book selection
  List<Map<String, dynamic>> getBookCategories() {
    return [
      {
        'category': 'Fiction',
        'image': 'assets/images/behind you is the sea .png'
      },
      {'category': 'Science', 'image': 'assets/images/OfT.png'},
      {'category': 'History', 'image': 'assets/images/earth.png'},
      {'category': 'Technology', 'image': 'assets/images/tech.png'},
      {'category': 'Art', 'image': 'assets/images/art.png'},
      {'category': 'Philosophy', 'image': 'assets/images/lost.png'},
      {'category': 'Business', 'image': 'assets/images/all.png'},
      {'category': 'Health', 'image': 'assets/images/health.png'},
      {'category': 'Education', 'image': 'assets/images/edu.png'},
      {'category': 'Biography', 'image': 'assets/images/we.png'},
      {'category': 'Travel', 'image': 'assets/images/sea.png'},
      {'category': 'Music', 'image': 'assets/images/music.png'},
      {'category': 'Sports', 'image': 'assets/images/sport.png'},
      {'category': 'Nature', 'image': 'assets/images/wo.png'},
      {'category': 'Classics', 'image': 'assets/images/ce.png'},
      {'category': 'Self-help', 'image': 'assets/images/self.png'},
      {'category': 'Mystery', 'image': 'assets/images/case.png'},
      {'category': 'Fantasy', 'image': 'assets/images/wolf.png'},
    ];
  }

  
}
