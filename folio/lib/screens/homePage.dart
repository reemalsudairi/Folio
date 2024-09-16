import 'package:flutter/material.dart';
import 'package:folio/screens/Profile/profile.dart'; // Import ProfilePage
import 'package:folio/screens/custom_bottom_navigation_bar.dart.dart'; // Import CustomBottomNavigationBar

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

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
          MaterialPageRoute(builder: (context) => HomePage()), // Navigate to Home
        );
        break;
      case 1:
       // Navigator.pushReplacement(
        //  context,
        //  MaterialPageRoute(builder: (context) => SearchPage()), // Placeholder for SearchPage
        //);
        break;
      case 2:
       // Navigator.pushReplacement(
        //  context,
        //  MaterialPageRoute(builder: (context) => LibraryPage()), // Placeholder for LibraryPage
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30), // Top spacing
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.notifications_active_outlined, size: 36, color: Color.fromARGB(255, 53, 31, 31)), 
                  Icon(Icons.person_2_outlined, size: 36, color: Color.fromARGB(255, 53, 31, 31))
                ],
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Good Day,\nNora!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 53, 31, 31),
                    )
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Yearly Goal', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 10),
                        Text('50/100', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: 0.5,
                      color: const Color.fromARGB(255, 247, 144, 173),
                      backgroundColor: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                      minHeight: 15,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text('Currently Reading', 
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 53, 31, 31),
                )
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}