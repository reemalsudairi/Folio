import 'package:flutter/material.dart';

class DynamicQuizPage extends StatefulWidget {
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
      'image': 'assets/images/pic4-removebg-preview.png', // Add image path
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
      'image': 'assets/images/pic2-removebg-preview.png', // Add image path
    },
    {
      'question': "Slow, medium, or fast paced read?",
      'options': ["Slow", "Medium", "Fast"],
      'image': 'assets/images/pic3-removebg-preview.png', // Add image path
    },
    {
      'question': "What language do you prefer?",
      'options': ["English", "Arabic"],
      'image': 'assets/images/pic1-removebg-preview.png', // Add image path
    },
  ];

  int currentQuestionIndex = 0;
  Map<String, List<String>> selectedAnswers = {}; // Store multiple selections per question

  void _toggleOption(String option) {
    setState(() {
      String question = questions[currentQuestionIndex]['question'];
      if (!selectedAnswers.containsKey(question)) {
        selectedAnswers[question] = [];
      }

      if (selectedAnswers[question]!.contains(option)) {
        selectedAnswers[question]!.remove(option); // Deselect if already selected
      } else {
        selectedAnswers[question]!.add(option); // Select if not selected
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var currentQuestion = questions[currentQuestionIndex];

    // Check if at least one option is selected for the current question
    bool isNextButtonEnabled = selectedAnswers[currentQuestion['question']] != null &&
        selectedAnswers[currentQuestion['question']]!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
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
            // Display image below the options
            Center(
            child: Image.asset(
              currentQuestion['image'],
              height: 250, // Reduced image size
              width: 250, // Reduced image width
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecommendationPage(answers: selectedAnswers),
                            ),
                          );
                        }
                      }
                    : null, // Disable button if no option is selected
                child: Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class RecommendationPage extends StatelessWidget {
  final Map<String, List<String>> answers;

  RecommendationPage({required this.answers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recommendations"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Based on your preferences:", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ...answers.entries.map((entry) => Text(
              "${entry.key}: ${entry.value.join(', ')}",
              style: TextStyle(fontSize: 18),
            )),
            // Display book recommendations here based on answers
          ],
        ),
      ),
    );
  }
}
