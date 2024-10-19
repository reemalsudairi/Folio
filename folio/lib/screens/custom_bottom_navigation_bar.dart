import 'package:flutter/material.dart';

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
      selectedItemColor: const Color(0xFFF790AD), // Pink color for selected item
      unselectedItemColor: const Color(0xFFB3B3B3), // Grey color for unselected item
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: 35), // Home icon
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined, size: 35), // Search icon
          label: 'Books',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined, size: 35), // Library icon
          label: 'Clubs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined, size: 35), // Profile icon
          label: 'Profile',
        ),
      ],
    );
  }
}


