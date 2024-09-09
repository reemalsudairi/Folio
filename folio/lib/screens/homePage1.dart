// import 'package:flutter/material.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({Key? key}) : super(key: key);

//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   String userName = 'Nora';
//   int yearlyGoalCurrent = 50;
//   int yearlyGoalTotal = 100;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F8F3),
//       body: SingleChildScrollView(  // Added SingleChildScrollView to ensure all content is visible
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 50), // Top spacing
//               // Top Row: User greeting and profile picture
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Good Day,\n$userName!',
//                     style: const TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Color.fromARGB(255, 53, 31, 31),
//                     ),
//                   ),
//                   const CircleAvatar(
//                    backgroundImage: AssetImage('assets/images/profile_pic.png'), 
//                     radius: 30,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               // Yearly Goal Section
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'Yearly Goal',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text(
//                           '$yearlyGoalCurrent/$yearlyGoalTotal',
//                           style: const TextStyle(fontSize: 18),
//                         ),
//                         const SizedBox(height: 5),
//                         LinearProgressIndicator(
//                           value: yearlyGoalCurrent / yearlyGoalTotal, // Dynamic progress value
//                           color: Colors.pink,
//                           backgroundColor: Colors.grey[300],
//                           minHeight: 8,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 30),
//               // Currently Reading Section
//               const Text(
//                 'Currently Reading',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: Color.fromARGB(255, 53, 31, 31),
//                 ),
//               ),
//               const SizedBox(height: 15),
//               // Book List
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
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: 0,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.search),
//             label: 'Search',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.book),
//             label: 'Library',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }

// // BookCard Widget
// class BookCard extends StatelessWidget {
//   final String imagePath;
//   final String title;
//   final String author;

//   const BookCard({
//     required this.imagePath,
//     required this.title,
//     required this.author,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 120,
//       margin: const EdgeInsets.only(right: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Image.asset(imagePath, height: 140, fit: BoxFit.cover),
//           const SizedBox(height: 10),
//           Text(
//             title,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           Text(
//             author,
//             style: const TextStyle(color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }
// }

