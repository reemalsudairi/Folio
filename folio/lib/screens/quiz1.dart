import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:folio/screens/book_details_page.dart';
import 'package:folio/screens/recommendation.dart';

class DynamicQuizPage extends StatefulWidget {
  final dynamic userId;

  const DynamicQuizPage({super.key, required this.userId});

  @override
  _DynamicQuizPageState createState() => _DynamicQuizPageState();
}

class _DynamicQuizPageState extends State<DynamicQuizPage> {
  final List<Map<String, dynamic>> questions = [
    {
      'question': "What genres sound good right now?",
      'options': [
        "Fiction",
        "Science",
        "History",
        "Technology",
        "Art",
        "Philosophy",
        "Business",
        "Health",
        "Education",
        "Biography",
        "Travel",
        "Music",
        "Sports",
        "Nature",
        "Classics",
        "Self-help",
        "Mystery",
        "Fantasy"
      ],
      'image': 'assets/images/pic4-removebg-preview.png',
    },
    {
      'question': "Slow, medium, or fast paced read?",
      'options': ["Slow", "Medium", "Fast"],
      'image': 'assets/images/pic3-removebg-preview.png',
    },
    {
      'question': "What language do you prefer?",
      'options': ["English", "Arabic"],
      'image': 'assets/images/pic2-removebg-preview.png',
    },
  ];

  int currentQuestionIndex = 0;
  Map<String, List<String>> selectedAnswers = {};

  void _toggleOption(String option) {
    setState(() {
      String question = questions[currentQuestionIndex]['question'];
      if (!selectedAnswers.containsKey(question)) {
        selectedAnswers[question] = [];
      }

      if (selectedAnswers[question]!.contains(option)) {
        selectedAnswers[question]!.remove(option);
      } else {
        selectedAnswers[question]!.add(option);
      }
    });
  }

Future<List<Map<String, dynamic>>> fetchBooksFromAPI() async {
  String genreQuery = selectedAnswers["What genres sound good right now?"]?.map((g) => "subject:${g.trim()}").join(" OR ") ?? "";
  String languageQuery = selectedAnswers["What language do you prefer?"]?.map((lang) => lang.toLowerCase() == "arabic" ? "ar" : "en").join("|") ?? "en";

  String query = [
    if (genreQuery.isNotEmpty) "($genreQuery)",
  ].join("+");

  String url = "https://www.googleapis.com/books/v1/volumes?q=$query&langRestrict=$languageQuery&maxResults=40&orderBy=newest";

  

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      return (data['items'] as List<dynamic>)
          .map<Map<String, dynamic>?>((item) {
            final volumeInfo = (item as Map<String, dynamic>)['volumeInfo'] as Map<String, dynamic>? ?? {};
            final pageCount = volumeInfo['pageCount'] ?? 0;
            final publishedYear = int.tryParse(volumeInfo['publishedDate']?.split("-")?.first ?? '') ?? 0;

            if (publishedYear < 2015 || volumeInfo['imageLinks']?['thumbnail'] == null || volumeInfo['description'] == null) {
              return null;
            }

            return {
              'id': item['id'],
              'title': volumeInfo['title'] ?? 'No Title',
              'authors': (volumeInfo['authors'] as List<dynamic>?)?.cast<String>() ?? ['Unknown'],
              'categories': (volumeInfo['categories'] as List<dynamic>?)?.cast<String>().join(', ') ?? '',
              'language': volumeInfo['language'] ?? 'Unknown',
              'imageUrl': volumeInfo['imageLinks']?['thumbnail'] ?? '',
              'description': volumeInfo['description'] ?? 'No description available.',
              'pageCount': pageCount,
              'publishedDate': volumeInfo['publishedDate'] ?? '',
              'averageRating': volumeInfo['averageRating'] ?? 0.0,
              'ratingsCount': volumeInfo['ratingsCount'] ?? 0,
              'matches': calculateMatches(volumeInfo),
            };
          })
          .where((book) => book != null)
          .toList()
          .cast<Map<String, dynamic>>()
          ..sort((a, b) => b['matches'].compareTo(a['matches']));
    } else {
      throw Exception("Failed to load books");
    }
  } catch (e) {
    print("Error fetching books: $e");
    return [];
  }
}


int calculateMatches(Map<String, dynamic> volumeInfo) {
  int score = 0;

  // Check for genre matches
  var categories = (volumeInfo['categories'] as List<dynamic>?)?.cast<String>() ?? [];
  if (selectedAnswers["What genres sound good right now?"]?.any((genre) => categories.any((cat) => cat.toLowerCase().contains(genre.toLowerCase()))) ?? false) {
    score += 3;
  }

  // Check for language match
  if (selectedAnswers["What language do you prefer?"]?.contains(volumeInfo['language']?.toLowerCase() ?? '') ?? false) {
    score += 3;
  }

  // Match pacing preferences
  int pageCount = volumeInfo['pageCount'] ?? 0;
  if (selectedAnswers["Slow, medium, or fast paced read?"]?.any((pacing) {
        if (pacing.toLowerCase() == "slow" && pageCount <= 150) return true;
        if (pacing.toLowerCase() == "medium" && pageCount > 150 && pageCount <= 300) return true;
        if (pacing.toLowerCase() == "fast" && pageCount > 300) return true;
        return false;
      }) ??
      false) {
    score += 2;
  }

  // Boost for recency
  int publishedYear = int.tryParse(volumeInfo['publishedDate']?.split("-")?.first ?? '') ?? 0;
  if (publishedYear >= 2020) {
    score += 2;
  }

  // Boost for popularity
  int ratingsCount = volumeInfo['ratingsCount'] ?? 0;
  if (ratingsCount > 100) {
    score += 2;
  }

  return score;
}



  @override
  Widget build(BuildContext context) {
    var currentQuestion = questions[currentQuestionIndex];
    bool isNextButtonEnabled =
        selectedAnswers[currentQuestion['question']] != null &&
            selectedAnswers[currentQuestion['question']]!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color.fromARGB(255, 53, 31, 31)),
          onPressed: () {
            if (currentQuestionIndex > 0) {
              setState(() {
                currentQuestionIndex--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentQuestion['question'],
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 53, 31, 31),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    (currentQuestion['options'] as List<String>).map((option) {
                  bool isSelected = selectedAnswers[currentQuestion['question']]
                          ?.contains(option) ??
                      false;
                  return ChoiceChip(
                    label: Text(option),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Color.fromARGB(255, 53, 31, 31),
                    ),
                    selected: isSelected,
                    selectedColor: Color(0xFFF790AD),
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (selected) {
                      _toggleOption(option);
                    },
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Image.asset(
                currentQuestion['image'],
                height: 250,
                width: 250,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 53, 31, 31),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: isNextButtonEnabled
                    ? () {
                        if (currentQuestionIndex < questions.length - 1) {
                          setState(() {
                            currentQuestionIndex++;
                          });
                        } else {
                          fetchBooksFromAPI().then ((books) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecommendationPage(
                                  answers: selectedAnswers,
                                  books: books, // Pass the books to the next page
                                  userId: FirebaseAuth.instance.currentUser !.uid,
                                ),
                              ),
                            );
                          }).catchError((e) {
                            // Handle error if needed
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Error fetching books")));
                          });
                        }
                      }
                    : null,
                child: Text("Next",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
