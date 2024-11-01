import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/createClubPage.dart';
import 'package:folio/screens/viewClub.dart';

class Clubs {
  final String id;
  final String name;
  final String description;
  final String picture;
  final int memberCount; // Add memberCount field

  Clubs({
    required this.id,
    required this.name,
    required this.description,
    required this.picture,
    this.memberCount = 1, // Default member count to 1
  });

  factory Clubs.fromMap(
      Map<String, dynamic> data, String documentId, int memberCount) {
    return Clubs(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      picture: data['picture'] ?? '',
      memberCount: memberCount, // Initialize memberCount
    );
  }
}

class ClubPage extends StatefulWidget {
  @override
  _ClubsPageState createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubPage> {
  final userId =
      FirebaseAuth.instance.currentUser?.uid ?? ''; // Current user ID
  List<Clubs> myClubs = [];
  List<Clubs> joinedClubs = [];
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    fetchClubs();
  }

 void fetchClubs() {
  if (userId.isEmpty) {
    print('User is not logged in.');
    return;
  }

  try {
    // Real-time listener for clubs owned by the current user (My Clubs)
    FirebaseFirestore.instance
        .collection('clubs')
        .where('ownerID', isEqualTo: userId)
        .snapshots()
        .listen((QuerySnapshot myClubsSnapshot) {
      List<Clubs> tempMyClubs = [];

      for (var doc in myClubsSnapshot.docs) {
        // Real-time listener for member count in each owned club
        FirebaseFirestore.instance
            .collection('clubs')
            .doc(doc.id)
            .collection('members')
            .snapshots()
            .listen((membersSnapshot) {
          int memberCount = membersSnapshot.size > 0 ? membersSnapshot.size : 1;

          Clubs club = Clubs.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
            memberCount,
          );

          int existingIndex = tempMyClubs.indexWhere((c) => c.id == doc.id);
          if (existingIndex >= 0) {
            tempMyClubs[existingIndex] = club;
          } else {
            tempMyClubs.add(club);
          }

          setState(() {
            myClubs = tempMyClubs;
          });
        });
      }

      // Remove clubs that were deleted from Firestore
      final updatedClubIds = myClubsSnapshot.docs.map((doc) => doc.id).toSet();
      tempMyClubs.removeWhere((club) => !updatedClubIds.contains(club.id));

      setState(() {
        myClubs = tempMyClubs;
      });
    });

    // Real-time listener for clubs the user has joined but does not own
    FirebaseFirestore.instance.collection('clubs').snapshots().listen(
      (QuerySnapshot joinedClubsSnapshot) {
        List<Clubs> tempJoinedClubs = [];

        for (var doc in joinedClubsSnapshot.docs) {
          var clubData = doc.data() as Map<String, dynamic>?;

          if (clubData != null && clubData.containsKey('ownerID')) {
            // Real-time listener for user's membership status in the club
            FirebaseFirestore.instance
                .collection('clubs')
                .doc(doc.id)
                .collection('members')
                .doc(userId)
                .snapshots()
                .listen((DocumentSnapshot memberSnapshot) {
              if (memberSnapshot.exists && clubData['ownerID'] != userId) {
                // Listen to real-time member count updates
                FirebaseFirestore.instance
                    .collection('clubs')
                    .doc(doc.id)
                    .collection('members')
                    .snapshots()
                    .listen((membersSnapshot) {
                  int memberCount = membersSnapshot.size > 0 ? membersSnapshot.size : 1;

                  Clubs club = Clubs.fromMap(
                    clubData,
                    doc.id,
                    memberCount,
                  );

                  int existingIndex = tempJoinedClubs.indexWhere((c) => c.id == doc.id);
                  if (existingIndex >= 0) {
                    tempJoinedClubs[existingIndex] = club;
                  } else {
                    tempJoinedClubs.add(club);
                  }

                  setState(() {
                    joinedClubs = tempJoinedClubs;
                    isLoading = false;
                  });
                });
              } else {
                // If the user is no longer a member, remove the club from the list
                tempJoinedClubs.removeWhere((c) => c.id == doc.id);
                setState(() {
                  joinedClubs = tempJoinedClubs;
                  isLoading = false;
                });
              }
            });
          }
        }
      },
      onError: (e) {
        print('Error fetching joined clubs: $e');
        setState(() {
          isLoading = false;
        });
      },
    );
  } catch (e) {
    print('Error setting up club listeners: $e');
    setState(() {
      isLoading = false;
    });
  }
}


  Stream<int> fetchMemberCount(String clubId) {
    try {
      // Listen for real-time updates from the members subcollection
      return FirebaseFirestore.instance
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .snapshots()
          .map((membersSnapshot) {
        // If the members collection is empty, return 1 to indicate only the owner.
        if (membersSnapshot.size == 0) {
          return 1;
        }
        // Otherwise, return the size of the members collection.
        return membersSnapshot.size;
      });
    } catch (e) {
      print('Error fetching member count for club $clubId: $e');
      // Return a stream with a single value of 1 in case of an error.
      return Stream.value(1);
    }
  }

  Widget buildClubCard(Clubs club) {
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
                      height: 120,
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
    appBar: AppBar(
      title: Text(
        'Book Clubs',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 26,
          color: Color(0xFF351F1F),
        ),
      ),
      backgroundColor: Color(0xFFF8F8F3),
      centerTitle: true,
    ),
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
    // Add the floating action button here
    floatingActionButton: Container(
  margin: const EdgeInsets.only(bottom: 20, right: 20), // Set margin of 20px down and right
  child: ClipOval(
    child: SizedBox(
      width: 70, // Set the width to make it bigger
      height: 70, // Set the height to make it bigger
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateClubPage(), // Navigate to the Create Club page
            ),
          );
        },
        backgroundColor: const Color(0xFFF790AD), // Set the background color to pink
        child: const Icon(
          Icons.add, // Use the add icon
          color: Colors.white, // Set the icon color to white for contrast
          size: 50, // Optional: Increase the icon size
        ),
      ),
    ),
  ),
),
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Positioning
  );
}}