import 'package:flutter/material.dart';
import 'package:folio/screens/Profile/profile.dart'; // Import ProfilePage
import 'package:folio/screens/custom_bottom_navigation_bar.dart.dart'; // Import CustomBottomNavigationBar

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on the selected index
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()), // Navigate to Home
        );
        break;
      case 1:
        // Uncomment and implement SearchPage
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => SearchPage()),
        // );
        break;
      case 2:
        // Uncomment and implement LibraryPage
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => LibraryPage()),
        // );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    int yearlyGoalCurrent = 50;
    int yearlyGoalTotal = 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Adjusted padding for consistency
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30), // Top spacing

            Row(
              mainAxisAlignment: MainAxisAlignment.end, // Align to the right
              children: [
                Icon(Icons.notifications_active_outlined, size: 36, color: Color.fromARGB(255, 53, 31, 31)),
                SizedBox(width: 16), // Added spacing between icons
                Icon(Icons.person_2_outlined, size: 36, color: Color.fromARGB(255, 53, 31, 31)),
              ],
            ),

            const SizedBox(height: 20), // Spacing between rows

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Good Day,\nNora!',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 53, 31, 31),
                  ),
                ),
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/profile_pic.png'),
                  radius: 40,
                ),
              ],
            ),

            const SizedBox(height: 20), // Spacing between sections

            // Yearly Goal Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Yearly Goal',
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '$yearlyGoalCurrent/$yearlyGoalTotal',
                        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: yearlyGoalCurrent / yearlyGoalTotal,
                    color: const Color.fromARGB(255, 247, 144, 173),
                    backgroundColor: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                    minHeight: 15,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30), // Spacing between sections

            // Currently Reading Section
            const Text(
              'Currently Reading',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 53, 31, 31),
              ),
            ),

            const SizedBox(height: 15),

            // Book List
            SizedBox(
              height: 200, // Adjusted height
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  BookCard(
                    imagePath: 'assets/book1.png',
                    title: 'The Sum of All Things',
                    author: 'Nicole Brooks',
                  ),
                  BookCard(
                    imagePath: 'assets/book2.png',
                    title: 'The Dreaming Arts',
                    author: 'Tom Maloney',
                  ),
                  BookCard(
                    imagePath: 'assets/book3.png',
                    title: 'The Hypothetical World',
                    author: 'Sophia Lewis',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// BookCard Widget
class BookCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String author;

  const BookCard({
    required this.imagePath,
    required this.title,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(imagePath, height: 140, fit: BoxFit.cover),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            author,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
