import 'package:flutter/material.dart';
import 'package:folio/screens/Profile/profile.dart'; // Import ProfilePage

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

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
        break;
      case 1:
        // Add navigation to the SearchPage
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SearchPage()));
        break;
      case 2:
        // Add navigation to the LibraryPage
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LibraryPage()));
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Existing UI elements...
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      selectedItemColor: const Color(0xFFF790AD), // Selected item color (pink)
      unselectedItemColor: const Color(0xFFB3B3B3), // Unselected item color (gray)
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: 35), // Home icon
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined, size: 35), // Search icon
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined, size: 35), // Library icon
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined, size: 35), // Profile icon
          label: 'Profile',
        ),
      ],
    );
  }
}
