import 'package:flutter/material.dart';
import 'package:folio/screens/book_details_page.dart';
import 'package:folio/services/google_books_service.dart';
import 'package:folio/utils.dart';

class RecommendationPage extends StatefulWidget {
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
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final GoogleBooksService _googleBooksService = GoogleBooksService();
  bool _isLoading = true;
  List<Map<String, dynamic>> books = []; // Store fetched book details
  String errorMessage = '';
    int currentIndex = 0;


  @override
  void initState() {
    super.initState();
    _fetchRecommendedBooks();
  }

  Future<void> _fetchRecommendedBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> fetchedBooks = [];

      for (Map<String, dynamic> book in widget.books) {
        final String bookId = book['id'] ?? '';
        debugPrint('Processing Book ID: $bookId');
        if (bookId.isNotEmpty) {
          final bookDetails = await _googleBooksService.getBookDetails(bookId);

          // Exclude books with explicit content or unwanted keywords
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

          bool isExcluded = _googleBooksService.containsExcludedKeyword(
            bookDetails['volumeInfo']['description']?.toLowerCase() ?? '',
            bookDetails['volumeInfo']['categories'] ?? [],
            excludedKeywords,
          );

          debugPrint(
              'Book "${bookDetails['volumeInfo']['title']}" excluded: $isExcluded');

          if (isExcluded) continue;

          // Get match result
          String matchResult = _getBookMatches(bookDetails);
          debugPrint(
              'Book "${bookDetails['volumeInfo']['title']}" matches: $matchResult');

          // Add only books with valid matches
          if (matchResult != "No specific matches") {
            bookDetails['matches'] = matchResult; // Add match string to book
            fetchedBooks.add(bookDetails);
          }
        }
      }

      // Separate books by language if multiple languages are selected
      List<String> languagePreferences = widget
              .answers["What language do you prefer?"]
              ?.map((e) => e.toLowerCase())
              .toList() ??
          [];
      debugPrint('Language Preferences: $languagePreferences');

      if (languagePreferences.length > 1) {
        // Balance books between selected languages
        fetchedBooks =
            _balanceBooksByLanguage(fetchedBooks, languagePreferences);
      }

      debugPrint('Final fetched books count: ${fetchedBooks.length}');

      setState(() {
        books = fetchedBooks;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error while fetching recommended books: $e');
      setState(() {
        errorMessage = 'Failed to load recommended books: $e';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchGroupedBooks() async {
    Map<String, List<Map<String, dynamic>>> groupedBooks = {};

    for (var category
        in widget.answers["What genres sound good right now?"] ?? []) {
      String categoryKey = category.toLowerCase();

      // Initialize the list for this category
      groupedBooks[categoryKey] = [];
    }

    for (Map<String, dynamic> book in widget.books) {
      final String bookId = book['id'] ?? '';
      if (bookId.isNotEmpty) {
        final bookDetails = await _googleBooksService.getBookDetails(bookId);

        // Check for category match
        List<String> bookGenres =
            ((bookDetails['volumeInfo']['categories'] ?? []) as List<dynamic>)
                .map((category) => category.toString().toLowerCase())
                .toList();

        for (String userCategory
            in widget.answers["What genres sound good right now?"] ?? []) {
          if (bookGenres
              .any((genre) => genre.contains(userCategory.toLowerCase()))) {
            // Add book to the corresponding category
            groupedBooks[userCategory.toLowerCase()]!.add(bookDetails);
          }
        }
      }
    }

    return groupedBooks;
  }

  List<Map<String, dynamic>> _filterBooksByLanguageAndPacing(
      List<Map<String, dynamic>> books) {
    List<Map<String, dynamic>> filteredBooks = [];
    var languagePreferences = widget.answers["What language do you prefer?"]
            ?.map((e) => e.toLowerCase())
            .toList() ??
        [];
    var pacingPreferences =
        widget.answers["Slow, medium, or fast paced read?"] ?? [];

    for (var book in books) {
      // Check for language match
      String bookLanguage =
          (book['volumeInfo']['language'] ?? '').toLowerCase();
      bool languageMatched = languagePreferences.isEmpty ||
          languagePreferences.contains(bookLanguage);

      // Check for pacing match
      int pageCount = book['volumeInfo']['pageCount'] ?? 0;
      bool pacingMatched = pacingPreferences.isEmpty ||
          pacingPreferences.any((pacing) {
            if (pacing.toLowerCase() == "slow" && pageCount <= 150) return true;
            if (pacing.toLowerCase() == "medium" &&
                pageCount > 150 &&
                pageCount <= 300) return true;
            if (pacing.toLowerCase() == "fast" && pageCount > 300) return true;
            return false;
          });

      // Add book if it matches both language and pacing
      if (languageMatched && pacingMatched) {
        filteredBooks.add(book);
      }
    }

    return filteredBooks;
  }

 List<Map<String, dynamic>> _balanceBooksByLanguage(
    List<Map<String, dynamic>> books, List<String> languages) {
  Map<String, List<Map<String, dynamic>>> booksByLanguage = {};

  // Group books by language
  for (var book in books) {
    String bookLanguage = (book['volumeInfo']['language'] ?? '').toLowerCase();
    booksByLanguage.putIfAbsent(bookLanguage, () => []);
    booksByLanguage[bookLanguage]!.add(book);
  }

  // Debugging
  debugPrint("Books grouped by language: $booksByLanguage");

  // Collect books evenly across languages
  List<Map<String, dynamic>> balancedBooks = [];
  int booksPerLanguage = (books.length / languages.length).floor();

  for (var language in languages) {
    var booksForLanguage = booksByLanguage[language] ?? [];
    balancedBooks.addAll(booksForLanguage.take(booksPerLanguage));
  }

  debugPrint("Balanced books count: ${balancedBooks.length}");
  return balancedBooks;
}


  bool _hasSpecificMatch(Map<String, dynamic> book) {
    bool genreMatched = false;
    bool languageMatched = false;
    bool pacingMatched = false;

    // Fetch user preferences
    var genrePreferences = widget.answers["What genres sound good right now?"]
            ?.map((e) => e.toLowerCase())
            .toList() ??
        [];
    var languagePreferences = widget.answers["What language do you prefer?"]
            ?.map((e) => e.toLowerCase())
            .toList() ??
        [];
    var pacingPreferences =
        widget.answers["Slow, medium, or fast paced read?"] ?? [];

    // Check for genre match
    if (genrePreferences.isNotEmpty) {
      List<String> bookGenres =
          ((book['volumeInfo']['categories'] ?? []) as List<dynamic>)
              .map((category) => category.toString().toLowerCase())
              .toList();

      genreMatched = genrePreferences.any((userGenre) =>
          bookGenres.any((bookGenre) => bookGenre.contains(userGenre)));
    }

    // Check for language match
    if (languagePreferences.isNotEmpty) {
      String bookLanguage =
          (book['volumeInfo']['language'] ?? '').toLowerCase();
      languageMatched = languagePreferences.contains(bookLanguage);
    }

    // Check for pacing match
    int pageCount = book['volumeInfo']['pageCount'] ?? 0;
    if (pacingPreferences.isNotEmpty) {
      pacingMatched = pacingPreferences.any((pacing) {
        if (pacing.toLowerCase() == "slow" && pageCount <= 150) return true;
        if (pacing.toLowerCase() == "medium" &&
            pageCount > 150 &&
            pageCount <= 300) return true;
        if (pacing.toLowerCase() == "fast" && pageCount > 300) return true;
        return false;
      });
    }

    // Debugging
    debugPrint(
        "Book: ${book['volumeInfo']['title']} | GenreMatched: $genreMatched, LanguageMatched: $languageMatched, PacingMatched: $pacingMatched");

    return genreMatched || languageMatched || pacingMatched;
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : books.isEmpty
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
                          padding:
                              const EdgeInsets.only(top: 20.0, bottom: 20.0),
                          child: Column(
                            children: const [
                              SizedBox(height: 8),
                              Text(
                                "Select one or two books you'd like to learn more about",
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
Expanded(
  child: Column(
    children: [
      Expanded(
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.65),
          itemCount: books.length,
          onPageChanged: (index) {
            setState(() {
              currentIndex = index; // Update the current page index
            });
          },
          itemBuilder: (context, index) {
            var book = books[index];
            String matches = _getBookMatches(book);

            return Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 50.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailsPage(
                        bookId: book['id'] ?? 'Unknown',
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 300, // Fixed height for the card
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Book cover image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(
                          book['volumeInfo']['imageLinks']?['thumbnail'] ?? '',
                          height: 300, // Fixed height for book cover
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.image_not_supported,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Book title
                      Text(
                        book['volumeInfo']['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Book author
                      Text(
                        (book['volumeInfo']['authors'] as List<dynamic>?)
                                ?.join(', ') ??
                            'Unknown Author',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Book details
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            (book['volumeInfo']['categories']
                                        as List<dynamic>?)
                                    ?.map((category) => category.toString())
                                    .join('/')
                                    .split('/')
                                    .take(5)
                                    .join(', ') ??
                                'Unknown Category',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${book['volumeInfo']['pageCount'] ?? 'N/A'} pages · ${_getPacingText(book['volumeInfo']['pageCount'] ?? 0)}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Language: ${_getPreferredLanguage(book['volumeInfo']['language'] ?? '', widget.answers["What language do you prefer?"])}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16), // Adjust spacing between content and indicator
   
      const SizedBox(height: 16), // Add padding below the indicators if needed
    ],
  ),
),



                      ],
                    ),
    );
  }

  String _getPacingText(int pageCount) {
  if (pageCount <= 150) {
    return 'slow-paced read';
  } else if (pageCount > 150 && pageCount <= 300) {
    return 'medium-paced read';
  } else {
    return 'fast-paced read';
  }
}

String _getPreferredLanguage(String bookLanguage, List<String>? userLanguages) {
  Map<String, String> languageMap = {
    'en': 'English',
    'ar': 'Arabic',
    // Add more mappings as needed
  };

  String readableLanguage = languageMap[bookLanguage] ?? bookLanguage.capitalize();
  if (userLanguages != null &&
      userLanguages.map((l) => l.toLowerCase()).contains(readableLanguage.toLowerCase())) {
    return readableLanguage;
  }
  return "Not specified";
}

String _getBookMatches(Map<String, dynamic> book) {
  List<String> matches = [];

  // Fetch user preferences
var genrePreferences = widget.answers["What genres sound good right now?"]
        ?.map((e) => e.toLowerCase())
        .toList() ??
    [];
debugPrint("User Genre Preferences: $genrePreferences");

  var languagePreferences = widget.answers["What language do you prefer?"]
          ?.map((e) => e.toLowerCase())
          .toList() ??
      [];
  var pacingPreferences =
      widget.answers["Slow, medium, or fast paced read?"] ?? [];

  // Check for genre match
List<dynamic>? categories = book['volumeInfo']['categories'];
debugPrint("Book Categories: $categories");
if (categories != null && genrePreferences.isNotEmpty) {
  List<String> bookGenres = categories
      .map((category) => category.toString().toLowerCase())
      .toList();

  debugPrint("Book Genres: $bookGenres");
  debugPrint("User Genres: $genrePreferences");

  List<String> matchedGenres = genrePreferences
      .where((userGenre) =>
          bookGenres.any((bookGenre) => bookGenre.contains(userGenre)))
      .toList();

  if (matchedGenres.isNotEmpty) {
    matches.add("Genres: ${matchedGenres.map((g) => g.capitalize()).join(', ')}");
    debugPrint("Matched Genres Added: ${matchedGenres.map((g) => g.capitalize()).join(', ')}");
  } else {
    debugPrint("No Genre Matches Found.");
  }
} else {
  debugPrint("Genres or preferences missing.");
}


  // Check for language match
  if (languagePreferences.isNotEmpty) {
    String bookLanguageCode =
        (book['volumeInfo']['language'] ?? '').toLowerCase();
    Map<String, String> languageMap = {
      'en': 'english',
      'ar': 'arabic',
    };
    String bookLanguage = languageMap[bookLanguageCode] ?? bookLanguageCode;

    if (languagePreferences.contains(bookLanguage)) {
      matches.add("Language: ${bookLanguage.capitalize()}");
      debugPrint("Matched Language: ${bookLanguage.capitalize()}");
    }
  }

  // Check for pacing match
  int pageCount = book['volumeInfo']['pageCount'] ?? 0;
  if (pacingPreferences.isNotEmpty) {
    for (var pacing in pacingPreferences) {
      if (pacing.toLowerCase() == "slow" && pageCount <= 150) {
        matches.add("Pacing: Slow");
        break;
      }
      if (pacing.toLowerCase() == "medium" &&
          pageCount > 150 &&
          pageCount <= 300) {
        matches.add("Pacing: Medium");
        break;
      }
      if (pacing.toLowerCase() == "fast" && pageCount > 300) {
        matches.add("Pacing: Fast");
        break;
      }
    }
  }

  debugPrint("Final Matches List: $matches");
  return matches.isNotEmpty ? matches.join(" · ") : "No specific matches";
}

}
