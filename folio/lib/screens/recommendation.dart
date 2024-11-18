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
      appBar: AppBar(
        title: Text(
          'Book Recommendations',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: books.isEmpty
          ? Center(
              child: Text(
                "No books found based on your preferences",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : PageView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                var book = books[index];

                // Build the matches string based on user answers
                String matches = _getBookMatches(book);

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Matches text above the book cover
                      Text(
                        "Matches:",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        matches,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 16),
                      // Book cover image
                      Center(
                        child: Image.network(
                          book['imageUrl'] ?? '',
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image_not_supported,
                            size: 200,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Book title and author below the image
                      Text(
                        book['title'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        book['authors'].join(', '),
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      Spacer(),
                      // Button to navigate to BookDetailsPage
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
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
                        child: Text(
                          'View Details',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
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

    // Check for genre match
    if (genrePreferences.isNotEmpty &&
        genrePreferences.any((genre) => book['categories'].toLowerCase().contains(genre))) {
      matches.add(book['categories']);
    }

    // Check for language match
    if (languagePreferences.contains(book['language']?.toLowerCase() ?? '')) {
      matches.add(book['language'] == 'en' ? "English" : "Arabic");
    }

    // Check if the book is in Arabic and the user prefers Arabic
    if (languagePreferences.contains("arabic") && book['language']?.toLowerCase() == "ar") {
      matches.add("Arabic");
    }
    // Check if the book is in Arabic and the user prefers Arabic
    if (languagePreferences.contains("english") && book['language']?.toLowerCase() == "en") {
      matches.add("English");
    }
    // Check for pacing match
    if (pacingPreference != null) {
      matches.add(pacingPreference);
    }

    // Construct the matches string
    return matches.isEmpty ? "No specific matches" : matches.join(" · ");
  }
}