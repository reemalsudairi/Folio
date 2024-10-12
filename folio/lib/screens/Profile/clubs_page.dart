<<<<<<< HEAD
=======
// clubs_page.dart
>>>>>>> 6969e297f39989e600c0a5f4bd1feaa2e8c0811a
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:folio/screens/viewClub.dart'; // If you need to get current user ID dynamically

>>>>>>> 6969e297f39989e600c0a5f4bd1feaa2e8c0811a

class Club {
  final String id;
  final String name;
  final String description;
  final String picture;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.picture,
  });

  factory Club.fromMap(Map<String, dynamic> data, String documentId) {
    return Club(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      picture: data['picture'] ?? '',
    );
  }
}

class ClubsPage extends StatefulWidget {
  @override
  _ClubsPageState createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  late String userId; // Initialize in initState
  List<Club> myClubs = [];
  List<Club> joinedClubs = [];

  @override
  void initState() {
    super.initState();
    // Fetch current user ID
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      fetchClubs();
    } else {
      // Handle case when user is not logged in
      print('User is not logged in');
      // Optionally, navigate to login page or show a message
    }
  }

  Future<void> fetchClubs() async {
    try {
<<<<<<< HEAD
      // Fetch clubs where the current user is the owner (My Clubs)
=======
      // Fetch clubs where the current user is the owner
>>>>>>> 6969e297f39989e600c0a5f4bd1feaa2e8c0811a
      QuerySnapshot myClubsSnapshot = await FirebaseFirestore.instance
          .collection('clubs')
          .where('ownerID', isEqualTo: userId)
          .get();

<<<<<<< HEAD
      // Fetch clubs where the current user is not the owner (Joined Clubs)
=======
      // Fetch clubs where the current user is a member but not the owner
      // Assuming you have a 'members' field as a list of user IDs
>>>>>>> 6969e297f39989e600c0a5f4bd1feaa2e8c0811a
      QuerySnapshot joinedClubsSnapshot = await FirebaseFirestore.instance
          .collection('clubs')
          .where('members', arrayContains: userId)
          .get();

      setState(() {
        // Debugging: Print fetched clubs for validation
        print("My Clubs:");
        for (var doc in myClubsSnapshot.docs) {
          print(
              "Club ID: ${doc.id}, Owner ID: ${doc['ownerID']}, User ID: $userId");
        }

        myClubs = myClubsSnapshot.docs
            .map((doc) =>
                Club.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        print("Joined Clubs:");
        for (var doc in joinedClubsSnapshot.docs) {
          print(
              "Club ID: ${doc.id}, Owner ID: ${doc['ownerID']}, User ID: $userId");
        }

        joinedClubs = joinedClubsSnapshot.docs
            .map((doc) =>
                Club.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } catch (e) {
      print('Error fetching clubs: $e');
      // Optionally, show a snackbar or alert to inform the user
    }
  }

  // Function to build club cards with tap functionality
  Widget buildClubCard(Club club) {
<<<<<<< HEAD
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
                    height: 140,
                    width: double.infinity,
                    child: Image.network(
                      club.picture,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 140,
                          width: double.infinity,
                          color: Colors.red,
                          child: Icon(Icons.error, color: Colors.white),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                )
              : Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      'No Image Available',
                      style:
                          TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                ),
          SizedBox(height: 10),
          Text(
            club.name,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
=======
    return GestureDetector(
      onTap: () {
        // Navigate to ViewClub page with the selected club's ID
        Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ViewClub(clubId: club.id),
  ),
);

      },
      child: Container(
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
                      height: 140,
                      width: double.infinity,
                      child: Image.network(
                        club.picture,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 140,
                            width: double.infinity,
                            color: Colors.red,
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
                    height: 140,
                    width: double.infinity,
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
            SizedBox(height: 10),
            Text(
              club.name,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
>>>>>>> 6969e297f39989e600c0a5f4bd1feaa2e8c0811a
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
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Clubs',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF351F1F),
                  ),
                ),
              ),
            ),
            myClubs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('You have no clubs.'),
                  )
                : GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: myClubs.length,
                    itemBuilder: (context, index) {
                      return buildClubCard(myClubs[index]);
                    },
                  ),
<<<<<<< HEAD
=======
            // Divider between My Clubs and Joined Clubs
>>>>>>> 6969e297f39989e600c0a5f4bd1feaa2e8c0811a
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(thickness: 2, height: 20, color: Colors.grey),
            ),
            // Joined Clubs Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Joined Clubs',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF351F1F),
                  ),
                ),
              ),
            ),
            joinedClubs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('You have not joined any clubs.'),
                  )
                : GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
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
