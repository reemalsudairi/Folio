import 'package:flutter/material.dart';
import 'package:folio/screens/Profile/clubs_page.dart';
import 'package:folio/screens/Profile/library_page.dart';
import 'package:folio/screens/Profile/reviews_page.dart';
import 'package:folio/screens/custom_bottom_navigation_bar.dart.dart'; // Import CustomBottomNavigationBar
import 'package:folio/screens/edit_profile.dart'; // Import the EditProfile page
import 'package:folio/screens/homePage.dart';
import 'package:folio/screens/settings.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0;

  static List<Widget> _pages = <Widget>[
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
        preferredSize: Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Color(0xFFF8F5F1),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: const Color.fromARGB(255, 35, 23, 23)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfile()), // Navigate to EditProfile
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.settings, color: const Color.fromARGB(255, 35, 23, 23)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()), // Navigate to SettingsPage
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
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
            SizedBox(height: 10),
            Container(
              width: 250,
              child: Text(
                'Book lover, always seeking new stories and perspectives.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color.fromARGB(255, 31, 24, 24),
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 30),
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
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: 0.5,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(Color(0xFFF790AD)),
                    minHeight: 13,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20), // Added spacing
            // Tabs and Indicator Line
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround, // Space around elements
                  children: [
                    TextButton(
                      onPressed: () => _onItemTapped(0), // Action when the button is pressed
                      child: Column(
                        children: [
                          Text(
                            'Library',
                            style: TextStyle(
                              fontSize: 18, // Font size of the text
                              fontWeight: FontWeight.bold, // Font weight of the text
                              color: _selectedIndex == 0 ? Colors.brown[800] : Colors.grey[600], // Color of the text
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _onItemTapped(1), // Action when the button is pressed
                      child: Column(
                        children: [
                          Text(
                            'Clubs',
                            style: TextStyle(
                              fontSize: 18, // Font size of the text
                              fontWeight: FontWeight.bold, // Font weight of the text
                              color: _selectedIndex == 1 ? Colors.brown[800] : Colors.grey[600], // Color of the text
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _onItemTapped(2), // Action when the button is pressed
                      child: Column(
                        children: [
                          Text(
                            'Reviews',
                            style: TextStyle(
                              fontSize: 18, // Font size of the text
                              fontWeight: FontWeight.bold, // Font weight of the text
                              color: _selectedIndex == 2 ? Colors.brown[800] : Colors.grey[600], // Color of the text
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
                    // Grey line
                    Container(
                      height: 2, // Height of the grey line
                      color: Colors.grey[300], // Color of the grey line
                      margin: EdgeInsets.symmetric(horizontal: 16), // Margin around the grey line
                    ),
                    // Brown line
                    AnimatedPositioned(
                      duration: Duration(milliseconds: 300), // Animation duration
                      left: _selectedIndex * (MediaQuery.of(context).size.width / 3) + 16, // Position of the brown line
                      top: -1, // Position the brown line slightly below the grey line
                      child: Container(
                        height: 4, // Height of the brown line
                        width: (MediaQuery.of(context).size.width / 3) - 32, // Width of the brown line
                        color: Colors.brown[800], // Color of the brown line
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Displaying the selected page content
            Expanded(
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 3, // Profile is selected by default
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
              break;
            case 1:
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(builder: (context) => SearchPage()),
              // );
              break;
            case 2:
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(builder: (context) => LibraryPage()),
              // );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
              break;
            default:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
              break;
          }
        },
      ),
    );
  }
}
