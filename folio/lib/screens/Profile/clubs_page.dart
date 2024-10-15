import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/viewClub.dart';

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
    this.memberCount = 1, // Default member count to 1
  });

  factory Club.fromMap(
      Map<String, dynamic> data, String documentId, int memberCount) {
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
  final userId =
      FirebaseAuth.instance.currentUser?.uid ?? ''; // Current user ID
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
      // Listen to real-time updates for clubs where the current user is the owner (My Clubs)
      FirebaseFirestore.instance
          .collection('clubs')
          .where('ownerID', isEqualTo: userId)
          .snapshots()
          .listen((QuerySnapshot myClubsSnapshot) async {
        List<Club> tempMyClubs = [];

        for (var doc in myClubsSnapshot.docs) {
          int memberCount = await fetchMemberCount(doc.id);
          tempMyClubs.add(Club.fromMap(
              doc.data() as Map<String, dynamic>, doc.id, memberCount));
        }

        // Update the state for myClubs
        setState(() {
          myClubs = tempMyClubs;
        });
      });

      // Listen to real-time updates for joined clubs
      FirebaseFirestore.instance
          .collection('clubs')
          .snapshots()
          .listen((QuerySnapshot joinedClubsSnapshot) async {
        List<Club> tempJoinedClubs = [];

        for (var doc in joinedClubsSnapshot.docs) {
          var clubData = doc.data() as Map<String, dynamic>?;

          // Safely check if the document's data is not null and contains 'ownerID'
          if (clubData != null && clubData.containsKey('ownerID')) {
            // Fetch the members subcollection to check if the user is a member
            DocumentSnapshot memberSnapshot = await FirebaseFirestore.instance
                .collection('clubs')
                .doc(doc.id)
                .collection('members')
                .doc(userId)
                .get();

            // Check if the user is in the members subcollection and not the owner
            if (memberSnapshot.exists && clubData['ownerID'] != userId) {
              int memberCount = await fetchMemberCount(doc.id);
              tempJoinedClubs.add(Club.fromMap(clubData, doc.id, memberCount));
            }
          }
        }

        // Update the state for joinedClubs
        setState(() {
          joinedClubs = tempJoinedClubs;
          isLoading = false; // Data fetching complete
        });
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
      return membersSnapshot.size + 1;
    } catch (e) {
      print('Error fetching member count for club $clubId: $e');
      return 1;
    }
  }

  Widget buildClubCard(Club club) {
    return GestureDetector(
      // Wrap with GestureDetector
      onTap: () {
        // Navigate to ViewClub page and pass the club ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewClub(
                clubId: club.id), // Replace with your actual ViewClub widget
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
                      height: 180,
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
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.withOpacity(0.2),
                      image: DecorationImage(
                        image: AssetImage('assets/images/clubs.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

            // Use Flexible for club name
            Flexible(
              child: Text(
                club.name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1, // Limits to 1 line
                overflow:
                    TextOverflow.ellipsis, // Adds "..." if the text is too long
              ),
            ),

            // Use Flexible for member count
            Flexible(
              child: Text(
                '${club.memberCount} members', // Display member count
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
                maxLines: 5, // Limits to 1 line
                overflow:
                    TextOverflow.ellipsis, // Adds "..." if the text is too long
              ),
            ),
          ],
        ),
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
                    child:
                        Divider(thickness: 2, height: 20, color: Colors.grey),
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
