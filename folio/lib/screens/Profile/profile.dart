import 'package:flutter/material.dart';
import 'package:folio/screens/Profile/clubs_page.dart';
import 'package:folio/screens/Profile/library_page.dart';
import 'package:folio/screens/Profile/reviews_page.dart';
import 'package:folio/screens/settings.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const LibraryPage(),
    const ClubsPage(),
    const ReviewsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F1),
      appBar: PreferredSize(
        preferredSize: const Size(412, 56),
        child: AppBar(
          backgroundColor: const Color(0xFFF8F5F1),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit,
                  color: Color.fromARGB(255, 35, 23, 23)),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings,
                  color: Color.fromARGB(255, 35, 23, 23)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFFF8F5F1),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
            const SizedBox(height: 5),
            Text(
              'Nora',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            const Text(
              '@Noraisreading',
              style: TextStyle(
                color: Color.fromARGB(255, 88, 71, 71),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const SizedBox(
              width: 250,
              child: Text(
                'Book lover, always seeking new stories and perspectives.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromARGB(255, 31, 24, 24),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildYearlyGoal(),
            const SizedBox(height: 20),
            // Tab-like navigation section
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () => _onItemTapped(0),
                      child: Column(
                        children: [
                          Text(
                            'Library',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedIndex == 0 ? Colors.brown[800] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _onItemTapped(1),
                      child: Column(
                        children: [
                          Text(
                            'Clubs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedIndex == 1 ? Colors.brown[800] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _onItemTapped(2),
                      child: Column(
                        children: [
                          Text(
                            'Reviews',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedIndex == 2 ? Colors.brown[800] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Container(
                      height: 2,
                      color: Colors.grey[300],
                      margin: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    AnimatedPositioned(
                      duration: Duration(milliseconds: 300),
                      left: _selectedIndex * (412 / 3) + 16,
                      top: -1,
                      child: Container(
                        height: 4,
                        width: 100,
                        color: Colors.brown[800],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _pages[_selectedIndex],
            ), // Display the selected page
          ],
        ),
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
