import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/first.page.dart'; // Import the WelcomePage
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationOn = true;

  // Function to show the sign-out confirmation dialog
  void _showSignOutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                _signOut(); // Call the sign-out function
              },
              child: const Text(
                'Sign Out',
                style:
                    TextStyle(color: Colors.red), // Optional: make the text red
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to sign out the user
  Future<void> _signOut() async {
    try {
      // Sign out the user from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate to WelcomePage after signing out
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      print('Error signing out: $e');
      // Optionally display an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e')),
      );
    }
  }

  // Function to show the delete account confirmation dialog
  void _showDeleteAccountConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                _deleteAccount();
              },
              child: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to delete the Firebase user and their Firestore data
  Future<void> _deleteAccount() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Step 1: Delete user data from Firestore
        await FirebaseFirestore.instance
            .collection('reader') // Assuming the collection is 'reader'
            .doc(user.uid)
            .delete();

        // Step 2: Delete user account from Firebase Authentication
        await user.delete();

        // Step 3: Sign out the user
        await FirebaseAuth.instance.signOut();

        // Step 4: Navigate to the WelcomePage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
      } catch (e) {
        print('Error deleting account: $e');
        // Optionally display an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    } else {
      print('No user is currently signed in.');
    }
  }

  // Function to launch the email client
  void _launchEmailClient() async {
    const url = 'mailto:Follio444@gmail.com';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A2E2B)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF4A2E2B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
        ),
        centerTitle: true,
      ),
      body: SizedBox(
        child: Center(
          child: Container(
            color: const Color(0xFFFDF8F4),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.notifications, color: Color(0xFF4A2E2B)),
                  title: const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Color(0xFF4A2E2B),
                      fontSize: 18,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  trailing: Switch(
                    value: _notificationOn,
                    onChanged: (value) {
                      setState(() {
                        _notificationOn = value;
                      });
                    },
                    activeColor: const Color(0xFFF790AD),
                    activeTrackColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xFF4A2E2B)),
                  title: const Text(
                    'Contact Us',
                    style: TextStyle(
                      color: Color(0xFF4A2E2B),
                      fontSize: 18,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  onTap: _launchEmailClient,
                ),
                const Spacer(),
                Center(
                  child: Column(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          _showSignOutConfirmationDialog(); // Show the sign-out confirmation dialog
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF790AD)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                          minimumSize: const Size(410, 48), // Add minimum size
                        ),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Color(0xFFF790AD),
                            fontSize: 16,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16), // Space between the buttons
                      ElevatedButton(
                        onPressed: () {
                          _showDeleteAccountConfirmationDialog(); // Show the delete account confirmation dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.red, // Set background color to red
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                          minimumSize: const Size(410, 48), // Add minimum size
                        ),
                        child: const Text(
                          'Delete Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50), // Space from the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}
