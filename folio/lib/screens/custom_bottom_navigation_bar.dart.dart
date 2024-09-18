import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  CustomBottomNavigationBar({required this.selectedIndex, required this.onTap});

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
          icon: SizedBox(
            width: 30,
            height: 30,
            child: Icon(Icons.home_outlined, size: 35),
          ),
          label: '', // No label
        ),
        BottomNavigationBarItem(
          icon: SizedBox(
            width: 30,
            height: 30,
            child: Icon(Icons.explore_outlined, size: 35),
          ),
          label: '', // No label
        ),
        BottomNavigationBarItem(
          icon: SizedBox(
            width: 30,
            height: 30,
            child: Icon(Icons.book_outlined, size: 35),
          ),
          label: '', // No label
        ),
        BottomNavigationBarItem(
          icon: SizedBox(
            width: 30,
            height: 30,
            child: Icon(Icons.person_outlined, size: 35),
          ),
          label: '', // No label
        ),
      ],
      backgroundColor: Colors.white,
    );
  }
}
