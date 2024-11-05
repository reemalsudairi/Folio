import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'AdminLoginPage.dart'; // Import your login page

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? adminUsername; // Make this nullable
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchAdminUsername();
  }

  // Fetch the admin's username from Firestore
  Future<void> _fetchAdminUsername() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String email = currentUser.email!;
        // Query Firestore to get the document where the email matches
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('admin')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          var userDoc = querySnapshot.docs.first;
          setState(() {
            adminUsername = userDoc.get('username'); // Retrieve admin's username
            isLoading = false; // Set loading to false after fetching
          });
        } else {
          print("No document found for email $email in Firestore.");
          setState(() {
            isLoading = false; // Set loading to false if no document is found
          });
        }
      }
    } catch (e) {
      print("Error fetching admin username: $e");
      setState(() {
        isLoading = false; // Set loading to false in case of error
      });
    }
  }

  // Function to show logout confirmation dialog
 // Function to show logout confirmation dialog
void _showLogoutConfirmationDialog() {
  showDialog(
    context: context,
    barrierDismissible: false, // Disable dismissal by clicking outside
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300, // Set a specific width for the dialog
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF790AD).withOpacity(0.9), // Pinkish background with opacity
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.exit_to_app, // Icon for sign out
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to log out?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Yes button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _logout(); // Call the logout function
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Change to desired color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Yes',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                // Cancel button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Change to desired color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}



  // Function to handle logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // Navigate to the login page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AdminLoginPage()), // Replace with your actual login page widget
      (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(0.0), // No padding for the top
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row for the image, greeting, and logout button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Greeting Text with margin and bold style
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0), // Add left margin
                    child: isLoading
                        ? CircularProgressIndicator()
                        : Text(
                            'Hello, Admin ${adminUsername ?? "Admin"}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold, // Make text bolder
                            ),
                          ),
                  ),
                  // Cropped Image
                  Container(
                    height: 90, // Cropped height (adjust as needed)
                    width: 170, // Keep the width same
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        heightFactor: 0.5, // Adjust to crop more from top and bottom
                        child: Image.asset(
                          'assets/images/Logo.png',
                          width: 170,
                          fit: BoxFit.cover, // Ensures the image covers the entire container
                        ),
                      ),
                    ),
                  ),
                  // Logout Button with right margin
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0), // Add right margin
                    child: ElevatedButton(
                      onPressed: () => _showLogoutConfirmationDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 0), // Reduced space below the row
              // Grey line under the row
              Container(
                height: 1, // Height of the line
                color: const Color.fromARGB(255, 216, 216, 216), // Color of the line
              ),
              const SizedBox(height: 10), // Adjusted space below the line
            ],
          ),
        ),
      ),
    );
  }
}
