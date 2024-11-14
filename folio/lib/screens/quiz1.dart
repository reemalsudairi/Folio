import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
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
      'question': "What genres sound good right now?",
      'options': [
        "Fiction", "Science", "History", "Technology", "Art", "Philosophy",
        "Business", "Health", "Education", "Biography", "Travel", "Music",
        "Sports", "Nature", "Classics", "Self-help", "Mystery", "Fantasy"
      ],
      'image': 'assets/images/pic4-removebg-preview.png',
    },
    {
      'question': "What mood are you in?",
      'options': [
        "Dark and suspenseful",
        "Lighthearted and funny",
        "Thought-provoking and moving",
        "Adventurous and exciting",
      ],
      'moodKeywords': {
        "Dark and suspenseful": ["Thriller", "Mystery", "Horror"],
        "Lighthearted and funny": ["Comedy", "Humor", "Feel-good"],
        "Thought-provoking and moving": ["Memoir", "Biography", "Literary Fiction"],
        "Adventurous and exciting": ["Adventure", "Fantasy", "Science Fiction"],
      },
      'image': 'assets/images/pic2-removebg-preview.png',
    },
    {
      'question': "Slow, medium, or fast paced read?",
      'options': ["Slow", "Medium", "Fast"],
      'image': 'assets/images/pic3-removebg-preview.png',
    },
    {
      'question': "What language do you prefer?",
      'options': ["English", "Arabic"],
      'image': 'assets/images/pic1-removebg-preview.png',
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
  // Genre and mood selection
  String genreQuery = selectedAnswers["What genres sound good right now?"]?.join("|") ?? "";
  String moodQuery = selectedAnswers["What mood are you in?"]?.expand((mood) => questions[1]['moodKeywords'][mood] ?? []).join("|") ?? "";
  
  // Page count filter based on selected pace
  int? minPages;
  int? maxPages;

  if (selectedAnswers["Slow, medium, or fast paced read?"]?.contains("Slow") ?? false) {
    minPages = 0;
    maxPages = 150; // Slow paced books: < 150 pages
  } else if (selectedAnswers["Slow, medium, or fast paced read?"]?.contains("Medium") ?? false) {
    minPages = 150;
    maxPages = 300; // Medium paced books: 150 - 300 pages
  } else if (selectedAnswers["Slow, medium, or fast paced read?"]?.contains("Fast") ?? false) {
    minPages = 300; // Fast paced books: > 300 pages
  }

  String pageCountQuery = '';
  if (minPages != null && maxPages != null) {
    pageCountQuery = "pages:$minPages..$maxPages";
  } else if (minPages != null) {
    pageCountQuery = "pages:>$minPages";
  }

  // Language selection
  String languageQuery = selectedAnswers["What language do you prefer?"]?.first.toLowerCase() ?? "en";
  
  // Constructing the Google Books API query URL
  String query = "subject:$genreQuery+$moodQuery+language:$languageQuery+$pageCountQuery";
  
  // Ensure no empty queries are included
  query = query.replaceAll(RegExp(r'\++$'), ''); // Remove trailing plus signs
  
  // API URL
  String url = "https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=10";

  print('API Request URL: $url'); // Log the request URL for debugging

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    List<Map<String, dynamic>> books = [];
    var data = json.decode(response.body);

    // Check if there are books in the response
    if (data['items'] != null) {
      for (var item in data['items']) {
        books.add({
          'id': item['id'],
          'title': item['volumeInfo']['title'],
          'authors': item['volumeInfo']['authors'] ?? ['Unknown'],
          'imageUrl': item['volumeInfo']['imageLinks']?['thumbnail'] ?? '',
        });
      }
    } else {
      print("No books found matching the query.");
    }

    return books;
  } else {
    print("Error fetching books: ${response.statusCode}");
    throw Exception("Failed to load books");
  }
}




  @override
  Widget build(BuildContext context) {
    var currentQuestion = questions[currentQuestionIndex];
    bool isNextButtonEnabled = selectedAnswers[currentQuestion['question']] != null &&
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
                children: (currentQuestion['options'] as List<String>).map((option) {
                  bool isSelected = selectedAnswers[currentQuestion['question']]?.contains(option) ?? false;
                  return ChoiceChip(
                    label: Text(option),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Color.fromARGB(255, 53, 31, 31),
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
                          fetchBooksFromAPI().then((books) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecommendationPage(
                                  answers: selectedAnswers,
                                  books: books, // Pass the books to the next page
                                  userId: FirebaseAuth.instance.currentUser!.uid,
                                ),
                              ),
                            );
                          }).catchError((e) {
                            // Handle error if needed
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching books")));
                          });
                        }
                      }
                    : null,
                child: Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
