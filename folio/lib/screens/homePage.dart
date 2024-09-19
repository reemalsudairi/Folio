import 'package:flutter/material.dart';
import 'package:folio/screens/Profile/profile.dart'; // Import ProfilePage
import 'package:folio/screens/categories_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Tracks the selected tab

  // List of pages for each tab
  static final List<Widget> _pages = <Widget>[
    const HomeContent(), // Home page content
    const CategoriesPage(), // CategoriesPage (Search page)
    const LibraryPage(), // Placeholder for LibraryPage
    const ProfilePage(), // ProfilePage
  ];

  // Update the index when a tab is selected
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      // Display the selected page
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor:
            const Color(0xFFF790AD), // Pink color for selected item
        unselectedItemColor:
            const Color(0xFFB3B3B3), // Grey color for unselected item
        showSelectedLabels: false, // No labels for selected items
        showUnselectedLabels: false, // No labels for unselected items
        onTap: _onItemTapped, // Handle tab selection
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 35),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined, size: 35),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined, size: 35),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined, size: 35),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Content for the Home tab
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    int yearlyGoalCurrent = 50;
    int yearlyGoalTotal = 100;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30), // Top spacing
            const Row(
              mainAxisAlignment: MainAxisAlignment.end, // Align to the right
              children: [
                Icon(Icons.notifications_active_outlined,
                    size: 36, color: Color.fromARGB(255, 53, 31, 31)),
                Icon(Icons.person_2_outlined,
                    size: 36, color: Color.fromARGB(255, 53, 31, 31))
              ],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Good Day,\nNora!',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 53, 31, 31),
                  ),
                ),
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/profile_pic.png'),
                  radius: 40,
                )
              ],
            ),
            const SizedBox(height: 20),
            // Yearly Goal Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Yearly Goal',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(
                            width: 10), // Add some space between the texts
                        Text(
                          '$yearlyGoalCurrent/$yearlyGoalTotal',
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: yearlyGoalCurrent / yearlyGoalTotal,
                      color: const Color.fromARGB(255, 247, 144, 173),
                      backgroundColor: Colors.grey[300],
                      minHeight: 15,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
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
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  BookCard(
                    imagePath: 'assets/images/book1.png',
                    title: 'The sum of all things',
                    author: 'Nicole Brooks',
                  ),
                  BookCard(
                    imagePath: 'assets/images/book2.png',
                    title: 'The Dreaming Arts',
                    author: 'Tom Maloney',
                  ),
                  BookCard(
                    imagePath: 'assets/images/book3.png',
                    title: 'The Hypothetical World',
                    author: 'Sophia Lewis',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder for the SearchPage
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Search Page Content',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

// Placeholder for the LibraryPage
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Library Page Content',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

// BookCard widget
class BookCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String author;

  const BookCard({
    super.key,
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
