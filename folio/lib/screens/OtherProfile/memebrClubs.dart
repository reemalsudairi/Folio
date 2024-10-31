import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/viewClub.dart';

class Club {
  final String id;
  final String name;
  final String description;
  final String picture;
  final int memberCount;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.picture,
    this.memberCount = 1,
  });

  factory Club.fromMap(
      Map<String, dynamic> data, String documentId, int memberCount) {
    return Club(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      picture: data['picture'] ?? '',
      memberCount: memberCount,
    );
  }
}

class Memebrclubs extends StatefulWidget {
  final String userId; // Accepts userId as a parameter

  const Memebrclubs({Key? key, required this.userId}) : super(key: key);

  @override
  _MemebrclubsState createState() => _MemebrclubsState();
}

class _MemebrclubsState extends State<Memebrclubs> {
  List<Club> myClubs = [];
  List<Club> joinedClubs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchClubs(widget.userId); // Use the provided userId
  }

  void fetchClubs(String userId) {
  if (userId.isEmpty) {
    print('User ID is not provided.');
    return;
  }

  // Fetch user's owned clubs (My Clubs)
  FirebaseFirestore.instance
      .collection('clubs')
      .where('ownerID', isEqualTo: userId)
      .snapshots()
      .listen((QuerySnapshot myClubsSnapshot) {
    List<Club> tempMyClubs = [];
    for (var doc in myClubsSnapshot.docs) {
      fetchMemberCount(doc.id).listen((memberCount) {
        Club club = Club.fromMap(
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
  });

  // Fetch joined clubs with real-time updates
  FirebaseFirestore.instance.collection('clubs').snapshots().listen(
    (QuerySnapshot joinedClubsSnapshot) {
      List<Club> tempJoinedClubs = [];

      for (var doc in joinedClubsSnapshot.docs) {
        var clubData = doc.data() as Map<String, dynamic>?;

        if (clubData != null && clubData.containsKey('ownerID')) {
          FirebaseFirestore.instance
              .collection('clubs')
              .doc(doc.id)
              .collection('members')
              .doc(userId)
              .snapshots()
              .listen((DocumentSnapshot memberSnapshot) {
            if (memberSnapshot.exists && clubData['ownerID'] != userId) {
              fetchMemberCount(doc.id).listen((memberCount) {
                Club club = Club.fromMap(
                  clubData,
                  doc.id,
                  memberCount,
                );

                int existingIndex =
                    tempJoinedClubs.indexWhere((c) => c.id == doc.id);
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
}


  Stream<int> fetchMemberCount(String clubId) {
    try {
      return FirebaseFirestore.instance
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .snapshots()
          .map((membersSnapshot) {
            return membersSnapshot.size == 0 ? 1 : membersSnapshot.size;
          });
    } catch (e) {
      print('Error fetching member count for club $clubId: $e');
      return Stream.value(1);
    }
  }

  Widget buildClubCard(Club club) {
    return GestureDetector(
      onTap: () {
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
            Flexible(
              child: Text(
                club.name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                '${club.memberCount} members',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // My Clubs Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'owned Clubs',
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
                          child: Text(' no owned clubs.'),
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
                          child: Text(' have not joined any clubs.'),
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
