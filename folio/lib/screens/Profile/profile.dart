import 'package:flutter/material.dart';
import 'package:folio/screens/Profile/clubs_page.dart';
import 'package:folio/screens/Profile/library_page.dart';
import 'package:folio/screens/Profile/reviews_page.dart';
import 'package:folio/screens/settings.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    LibraryPage(),
    ClubsPage(),
    ReviewsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F5F1),
      appBar: PreferredSize(
        preferredSize: Size(412, 56),
        child: AppBar(
          backgroundColor: Color(0xFFF8F5F1),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: const Color.fromARGB(255, 35, 23, 23)),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.settings, color: const Color.fromARGB(255, 35, 23, 23)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        width: 412,
        height: 915,
        color: Color(0xFFF8F5F1),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
            SizedBox(height: 5),
            Text(
              'Nora',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            Text(
              '@Noraisreading',
              style: TextStyle(
                color: const Color.fromARGB(255, 88, 71, 71),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 250,
              child: Text(
                'Book lover, always seeking new stories and perspectives.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color.fromARGB(255, 31, 24, 24),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildYearlyGoal(),
            SizedBox(height: 20),
            Expanded(child: _pages[_selectedIndex]), // Display the selected page
          ],
        ),
      ),
    bottomNavigationBar: BottomNavigationBar(
  currentIndex: 0,
  selectedItemColor: const Color(0xFFF790AD), // Selected item color
  unselectedItemColor: const Color(0xFFB3B3B3),
  showSelectedLabels: false,
  showUnselectedLabels: false, // Unselected item color
  items: const [
    BottomNavigationBarItem(
      icon: SizedBox(
        child: Icon(Icons.home_outlined, size: 35), // Set the icon size
        width: 30, // Set the icon width
        height: 30, // Set the icon height
      ),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        child: Icon(Icons.explore_outlined, size: 35), // Set the icon size
        width: 30, // Set the icon width
        height: 30, // Set the icon height
      ),
      label: 'Search',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        child: Icon(Icons.book_outlined, size: 35), // Set the icon size
        width: 30, // Set the icon width
        height: 30, // Set the icon height
      ),
      label: 'Library',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        child: Icon(Icons.person_outlined, size: 35), // Set the icon size
        width: 30, // Set the icon width
        height: 30, // Set the icon height
      ),
      label: 'Profile',
    ),
  ],
),
    );
  }

  Widget _buildYearlyGoal() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 30),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Yearly Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
              Text(
                '50/100',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: 0.5,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation(Color(0xFFF790AD)),
            minHeight: 13,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
        ],
      ),
    );
  }
}
