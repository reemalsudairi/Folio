// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Club {
  final String id;
  final String name;
  final String description;
  final String picture;

  Club({required this.id, required this.name, required this.description, required this.picture});

  factory Club.fromMap(Map<String, dynamic> data, String documentId) {
    return Club(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      picture: data['picture'] ?? '', // Added picture field
    );
  }
}

class ClubsPage extends StatefulWidget {
  @override
  _ClubsPageState createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  final String userId = 'currentUserId'; // Replace with the current user ID
  List<Club> myClubs = [];
  List<Club> joinedClubs = [];

  @override
  void initState() {
    super.initState();
    fetchClubs();
  }

  Future<void> fetchClubs() async {
    try {
      QuerySnapshot myClubsSnapshot = await FirebaseFirestore.instance
          .collection('clubs')
          .where('ownerID', isEqualTo: userId)
          .get();

      QuerySnapshot joinedClubsSnapshot = await FirebaseFirestore.instance
          .collection('clubs')
          .where('ownerID', isNotEqualTo: userId)
          .get();

      setState(() {
        myClubs = myClubsSnapshot.docs
            .map((doc) => Club.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        joinedClubs = joinedClubsSnapshot.docs
            .map((doc) => Club.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } catch (e) {
      print('Error fetching clubs: $e');
    }
  }

  Widget buildClubCard(Club club) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          club.picture.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 140, // Same size as the image box
              width: double.infinity,
              child: Image.network(
                club.picture,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.red, // Shows red if there's an error
                    child: Icon(Icons.error, color: Colors.white),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
          )
              : Container(
            height: 140, // Match the image box height
            width: double.infinity, // Match the width of the image
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                'No Image Available',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          ),
          SizedBox(height: 10), // Spacing between image and text
          Text(
            club.name,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F3),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // My Clubs Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft, // Align text to the left
                child: Text(
                  'My Clubs',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF351F1F)),
                ),
              ),
            ),
            myClubs.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('You have no clubs.'),
            )
                : GridView.builder(
              physics: NeverScrollableScrollPhysics(), // Prevent scrolling
              shrinkWrap: true, // Allow it to take only the required space
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two clubs per row
                childAspectRatio: 0.75, // Adjust the aspect ratio as needed
              ),
              itemCount: myClubs.length,
              itemBuilder: (context, index) {
                return buildClubCard(myClubs[index]);
              },
            ),
            // Divider between My Clubs and Joined Clubs with padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Space before and after the line
              child: Divider(thickness: 2, height: 20, color: Colors.grey), // Set divider color to gray
            ),
            // Joined Clubs Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft, // Align text to the left
                child: Text(
                  'Joined Clubs',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF351F1F)),
                ),
              ),
            ),
            joinedClubs.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('You have not joined any clubs.'),
            )
                : GridView.builder(
              physics: NeverScrollableScrollPhysics(), // Prevent scrolling
              shrinkWrap: true, // Allow it to take only the required space
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two clubs per row
                childAspectRatio: 0.75, // Adjust the aspect ratio as needed
              ),
              itemCount: joinedClubs.length,
              itemBuilder: (context, index) {
                return buildClubCard(joinedClubs[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}
