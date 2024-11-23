import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
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
      'question': "What are you in the mood for?",
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
  // Build genre query
  String genreQuery = selectedAnswers["What are you in the mood for?"]
          ?.map((g) => "subject:${g.trim().toLowerCase()}")
          .join(" OR ") ??
      "";

  // Build language query
  String languageQuery = selectedAnswers["What language do you prefer?"]
          ?.map((lang) => lang.toLowerCase() == "arabic" ? "ar" : "en")
          .join("|") ??
      "en";

  // Ensure fallback if no genre or language is selected
  String query = genreQuery.isNotEmpty ? "$genreQuery" : "bestseller";
  String url =
      "https://www.googleapis.com/books/v1/volumes?q=$query&langRestrict=$languageQuery&maxResults=40&orderBy=newest";

  debugPrint("API Request URL: $url");

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      debugPrint("Total books fetched: ${data['items']?.length ?? 0}");

      return (data['items'] as List<dynamic>)
          .map<Map<String, dynamic>?>((item) {
            final volumeInfo =
                (item as Map<String, dynamic>)['volumeInfo'] as Map<String, dynamic>? ?? {};
                //here
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
              //here
              'publishedDate': volumeInfo['publishedDate'] ?? '',
              'averageRating': volumeInfo['averageRating'] ?? 0.0,
              'ratingsCount': volumeInfo['ratingsCount'] ?? 0,
              'matches': calculateMatches(volumeInfo),

              'pageCount': volumeInfo['pageCount'] ?? 0,
            };
          })
          .where((book) => book != null)
          .toList()
          
          .cast<Map<String, dynamic>>();
//delete sort
    } else {
      debugPrint("API Error: ${response.statusCode}");
      throw Exception("Failed to load books");
    }
  } catch (e) {
    debugPrint("Error fetching books: $e");
    return [];
  }
}



int calculateMatches(Map<String, dynamic> volumeInfo) {
  int score = 0;

  // Fetch book categories and user-selected genres
  var categories = (volumeInfo['categories'] as List<dynamic>?)
          ?.cast<String>() ??
      [];
  var userGenres = selectedAnswers["What are you in the mood for?"] ?? [];

  // Check for genre matches
  if (doesCategoryMatch(categories, userGenres)) {
    score += 3; // Increase score for matching genres
  }

  // Check for language match
  if (selectedAnswers["What language do you prefer?"]
          ?.contains(volumeInfo['language']?.toLowerCase() ?? '') ??
      false) {
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
    body: Column(
      children: [
        // Progress Bar (Fixed position at the top)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(questions.length, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= currentQuestionIndex
                            ? Color(0xFFF790AD) // Pink for completed segments
                            : Colors.grey[300], // Grey for remaining segments
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        SizedBox(height: 20), // Space below the progress bar

        // Main Content (Split into question, options, and image + button section)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Section
                Text(
                  currentQuestion['question'],
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 53, 31, 31),
                  ),
                ),
                SizedBox(height: 20),

                // Options Section
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: (currentQuestion['options'] as List<String>)
                      .map((option) {
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
              ],
            ),
          ),
        ),

        // Image and Button Section
        Padding(
          padding: const EdgeInsets.only(bottom: 50.0), // Adjust spacing for the button
          child: Column(
            children: [
              // Image (Consistently above the button)
              Image.asset(
                currentQuestion['image'],
                height: 180,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20), // Space between the image and the button

              // Next Button
              ElevatedButton(
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
                          fetchBooksFromAPI().then((books) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecommendationPage(
                                  answers: selectedAnswers,
                                  books: books,
                                  userId: FirebaseAuth.instance.currentUser!.uid,
                                ),
                              ),
                            );
                          }).catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error fetching books")));
                          });
                        }
                      }
                    : null,
                child: Text(
                  "Next",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
bool doesCategoryMatch(List<String> bookCategories, List<String> userGenres) {
  // Normalize book categories and user genres
  var normalizedBookGenres = bookCategories
      .map((category) => category
          .split('/') // Split hierarchical categories
          .map((c) => c.trim().toLowerCase())) // Trim and lowercase
      .expand((e) => e) // Flatten the list
      .toList();

  var normalizedUserGenres =
      userGenres.map((genre) => genre.trim().toLowerCase()).toList();

  // Check if any user genre matches any normalized book genre
  return normalizedUserGenres.any((userGenre) =>
      normalizedBookGenres.any((bookGenre) => bookGenre.contains(userGenre)));
}

}
