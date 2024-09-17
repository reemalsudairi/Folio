import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar(
      {super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      selectedItemColor: const Color(0xFFF790AD), // Selected item color (pink)
      unselectedItemColor:
          const Color(0xFFB3B3B3), // Unselected item color (gray)
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
      onTap: onTap,
    );
  }
}
