import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Club {
  final String id;
  final String name;
  final String description;
  final String picture;
  final int memberCount; // Add memberCount field

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.picture,
    this.memberCount = 0, // Default member count to 0
  });

  factory Club.fromMap(Map<String, dynamic> data, String documentId, int memberCount) {
    return Club(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      picture: data['picture'] ?? '',
      memberCount: memberCount, // Initialize memberCount
    );
  }
}

class ClubsPage extends StatefulWidget {
  @override
  _ClubsPageState createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? ''; // Current user ID
  List<Club> myClubs = [];
  List<Club> joinedClubs = [];
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    fetchClubs();
  }

  Future<void> fetchClubs() async {
    if (userId.isEmpty) {
      print('User is not logged in.');
      return;
    }
    try {
      // Fetch clubs where the current user is the owner (My Clubs)
      QuerySnapshot myClubsSnapshot = await FirebaseFirestore.instance
          .collection('clubs')
          .where('ownerID', isEqualTo: userId)
          .get();

      // Fetch clubs where the current user is not the owner (Joined Clubs)
      QuerySnapshot joinedClubsSnapshot = await FirebaseFirestore.instance
          .collection('clubs')
          .where('ownerID', isNotEqualTo: userId)
          .get();

      List<Club> tempMyClubs = [];
      List<Club> tempJoinedClubs = [];

      // Get member counts for My Clubs
      for (var doc in myClubsSnapshot.docs) {
        int memberCount = await fetchMemberCount(doc.id);
        tempMyClubs.add(Club.fromMap(doc.data() as Map<String, dynamic>, doc.id, memberCount));
      }

      // Get member counts for Joined Clubs
      for (var doc in joinedClubsSnapshot.docs) {
        int memberCount = await fetchMemberCount(doc.id);
        tempJoinedClubs.add(Club.fromMap(doc.data() as Map<String, dynamic>, doc.id, memberCount));
      }

      setState(() {
        myClubs = tempMyClubs;
        joinedClubs = tempJoinedClubs;
        isLoading = false; // Data fetching complete
      });
    } catch (e) {
      print('Error fetching clubs: $e');
      setState(() {
        isLoading = false; // In case of error, stop loading
      });
    }
  }

  Future<int> fetchMemberCount(String clubId) async {
    try {
      QuerySnapshot membersSnapshot = await FirebaseFirestore.instance
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .get();
      return membersSnapshot.size;
    } catch (e) {
      print('Error fetching member count for club $clubId: $e');
      return 0;
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
          SizedBox(height: 6),
          Text(
            '${club.memberCount} members', // Display member count
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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
      body: isLoading // Check loading state
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : SingleChildScrollView(
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
