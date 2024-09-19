import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
     int yearlyGoalCurrent = 50;
     int yearlyGoalTotal = 100;
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
  mainAxisAlignment: MainAxisAlignment.end, // Align to the right
  children: [
    Icon(Icons.notifications_active_outlined, size: 36, color: Color.fromARGB(255, 53, 31, 31)), 
    Icon(Icons.person_2_outlined, size: 36, color: Color.fromARGB(255, 53, 31, 31))
  ],
),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Good Day,\nNora!',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 53, 31, 31),
                  )
                  ),
                  const CircleAvatar(
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
          const Text('Yearly Goal',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 10), // Add some space between the texts
          Text('$yearlyGoalCurrent/$yearlyGoalTotal',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      const SizedBox(height: 5),
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
              ),
              const SizedBox(height: 30),
            // Currently Reading Section
            const Text('Currently Reading', 
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 53, 31, 31),
            ),
            ),
            const SizedBox(height: 15),
            // Book List
//               SizedBox(
//                 height: 200,
//                 child: ListView(
//                   scrollDirection: Axis.horizontal,
//                   // children: const [
//                   //   BookCard(
//                   //     imagePath: 'assets/book1.png',
//                   //     title: 'The sum of all things',
//                   //     author: 'Nicole Brooks',
//                   //   ),
//                   //   BookCard(
//                   //     imagePath: 'assets/book2.png',
//                   //     title: 'The Dreaming Arts',
//                   //     author: 'Tom Maloney',
//                   //   ),
//                   //   BookCard(
//                   //     imagePath: 'assets/book3.png',
//                   //     title: 'The Hypothetical World',
//                   //     author: 'Sophia Lewis',
//                   //   ),
//                   // ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),

              
            ],
           )
          
        )
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
        width: 30, // Set the icon width
        height: 30,
        child: Icon(Icons.home_outlined, size: 35), // Set the icon height
      ),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 30, // Set the icon width
        height: 30,
        child: Icon(Icons.explore_outlined, size: 35), // Set the icon height
      ),
      label: 'Search',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 30, // Set the icon width
        height: 30,
        child: Icon(Icons.book_outlined, size: 35), // Set the icon height
      ),
      label: 'Library',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 30, // Set the icon width
        height: 30,
        child: Icon(Icons.person_outlined, size: 35), // Set the icon height
      ),
      label: 'Profile',
    ),
  ],
)
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
