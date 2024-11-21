import 'package:flutter/material.dart';
import 'package:folio/screens/book_details_page.dart';

class RecommendationPage extends StatelessWidget {
  final Map<String, List<String>> answers; // User's quiz answers
  final List<Map<String, dynamic>> books; // Combined books from APIs
  final String userId;

  const RecommendationPage({
    super.key,
    required this.answers,
    required this.books,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: const Color(0xFFF8F8F3),
      appBar: AppBar(
        title: const Text(
          "Pick your next book",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black), // 'X' button
            onPressed: () {
              int popCount = 4;
              for (int i = 0; i < popCount; i++) {
                if (Navigator.canPop(context)) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: books.isEmpty
          ? const Center(
              child: Text(
                "No books found based on your preferences",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                  child: Column(
                    children: const [
                      SizedBox(height: 8),
                      Text(
                        "Select one or two books you'd like to learn more about",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
child: PageView.builder(
  controller: PageController(viewportFraction: 0.65), // Show parts of adjacent books
  itemCount: books.length,
  itemBuilder: (context, index) {
    var book = books[index];
    String matches = _getBookMatches(book);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailsPage(
                bookId: book['id'] ?? 'Unknown',
                userId: userId,
              ),
            ),
          );
        },
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7, // Adjust width
          height: MediaQuery.of(context).size.height * 0.2, // Adjust height
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),

          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Matches section
              Text(
                "Matches:",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                matches,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              // Book cover image
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  book['imageUrl'] ?? '',
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Book title and description
              Column(
                children: [
                  Text(
                    book['title'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book['authors'].join(', '),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Book category and pages
              Text(
                "${book['categories']} · ${book['pageCount']} pages",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  },
),

                ),
              ],
            ),
    );
  }

  /// Helper function to build a string with matches based on user preferences
String _getBookMatches(Map<String, dynamic> book) {
  List<String> matches = [];

  // Fetch user preferences
  var genrePreferences = answers["What genres sound good right now?"]?.map((e) => e.toLowerCase()).toList() ?? [];
  var languagePreferences = answers["What language do you prefer?"]?.map((e) => e.toLowerCase()).toList() ?? [];
  var pacingPreference = answers["Slow, medium, or fast paced read?"]?.first.toLowerCase();

  // Debugging preferences and book data
  debugPrint("User Genre Preferences: $genrePreferences");
  debugPrint("Book Data: $book");
  debugPrint("Book Categories (raw): ${book['categories']}");
  debugPrint("Book Language (raw): ${book['language']}");

  // Check for genre match
  if (genrePreferences.isNotEmpty) {
    List<String> bookGenres = (book['categories'] ?? '')
        .toLowerCase()
        .split(',')
        .map((genre) => genre.trim())
        .toList();

    debugPrint("Normalized Book Genres: $bookGenres");

    bool hasGenreMatch = genrePreferences.any((genre) {
      debugPrint("Checking if '$genre' matches any of the book's genres");
      return bookGenres.any((bookGenre) {
        debugPrint("Comparing with book genre: '$bookGenre'");
        return bookGenre.contains(genre);
      });
    });

    if (hasGenreMatch) {
      matches.add("Genre match: ${book['categories']}");
    } else {
      debugPrint("No genre match for: ${book['categories']}");
    }
  }

  // Check for language match
  if (languagePreferences.isNotEmpty) {
    String bookLanguageCode = (book['language'] ?? '').toLowerCase();
    Map<String, String> languageMap = {
      'en': 'english',
      'ar': 'arabic',
    };
    String bookLanguage = languageMap[bookLanguageCode] ?? bookLanguageCode;

    if (languagePreferences.contains(bookLanguage)) {
      matches.add(bookLanguage[0].toUpperCase() + bookLanguage.substring(1)); // Capitalize
    } else {
      debugPrint("No language match for: $bookLanguage");
    }
  }

  // Check for pacing match
  if (pacingPreference != null) {
    matches.add("$pacingPreference");
  } else {
    debugPrint("No pacing preference.");
  }

  // Debug final matches
  debugPrint("Matches for this book: ${matches.join(' · ')}");

  return matches.isEmpty ? "No specific matches" : matches.join(" · ");
}


}
