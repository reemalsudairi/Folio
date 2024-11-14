import 'package:flutter/material.dart';
import 'package:folio/screens/book_details_page.dart';

class RecommendationPage extends StatelessWidget {
  final Map<String, List<String>> answers; // User's answers to quiz questions
  final List<Map<String, dynamic>> books; // List of recommended books
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
      appBar: AppBar(title: Text('Book Recommendations')),
      body: books.isEmpty
          ? Center(child: Text("No books found based on your preferences"))
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
                        "Matches your preferences: $matches",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Book cover image
                      Image.network(
                        book['imageUrl'] ?? '',
                        height: 200,
                        fit: BoxFit.cover,
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailsPage(
                                bookId: book['id'],
                                userId: userId,
                              ),
                            ),
                          );
                        },
                        child: Text('View Details'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Helper function to build a string with matches based on user preferences
// Helper function to build a string with matches based on user preferences
String _getBookMatches(Map<String, dynamic> book) {
  List<String> matches = [];

  // Normalize user preferences and book data for case-insensitive comparison
  var genreMatches = answers["What genres sound good right now?"]?.map((e) => e.toLowerCase()).toList() ?? [];
  var moodMatches = answers["What mood are you in?"]?.map((e) => e.toLowerCase()).toList() ?? [];
  var languageMatches = answers["What language do you prefer?"]?.map((e) => e.toLowerCase()).toList() ?? [];

if (genreMatches.contains(book['genre']?.toLowerCase() ?? "")) {
  matches.add("Genre: ${book['genre']}");
}
if (moodMatches.contains(book['mood']?.toLowerCase() ?? "")) {
  matches.add("Mood: ${book['mood']}");
}
if (languageMatches.contains(book['language']?.toLowerCase() ?? "")) {
  matches.add("Language: ${book['language']}");
}


  // Return a string that lists the matches
  return matches.isEmpty ? "No specific matches" : matches.join(", ");
}

}
