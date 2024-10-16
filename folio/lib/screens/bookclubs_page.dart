import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/createClubPage.dart';
import 'package:folio/screens/viewClub.dart';

class Club {
  final String id;
  final String name;
  final String picture;
  final int memberCount;

  Club(
      {required this.id,
      required this.name,
      required this.picture,
      this.memberCount = 1});

  factory Club.fromMap(
      Map<String, dynamic> data, String documentId, int memberCount) {
    return Club(
      id: documentId,
      name: data['name'] ?? '',
      picture: data['picture'] ?? '',
      memberCount: memberCount,
    );
  }
}

class Clubs extends StatelessWidget {
  const Clubs({super.key});

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
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color(0xFFF8F8F3),
      body: const ClubsBody(),
    );
  }
}

class ClubsBody extends StatefulWidget {
  const ClubsBody({super.key});

  @override
  _ClubsBodyState createState() => _ClubsBodyState();
}

class _ClubsBodyState extends State<ClubsBody> {
  List<Club> clubs = [];
  List<Club> filteredClubs = [];
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    fetchClubs();
  }

  Future<void> fetchClubs() async {
    try {
      QuerySnapshot clubsSnapshot =
          await FirebaseFirestore.instance.collection('clubs').get();
      List<Club> fetchedClubs = [];

      for (var doc in clubsSnapshot.docs) {
        int memberCount = await fetchMemberCount(doc.id);
        fetchedClubs.add(Club.fromMap(
            doc.data() as Map<String, dynamic>, doc.id, memberCount));
      }

      setState(() {
        clubs = fetchedClubs;
        filteredClubs = fetchedClubs;
        isLoading = false; // Data fetching is complete
      });
    } catch (e) {
      print('Error fetching clubs: $e');
      setState(() {
        isLoading = false; // Set loading to false in case of error as well
      });
    }
  }

  Future<int> fetchMemberCount(String clubId) async {
    try {
    // Get the members subcollection snapshot
    QuerySnapshot membersSnapshot = await FirebaseFirestore.instance
        .collection('clubs')
        .doc(clubId)
        .collection('members')
        .get();

    // If the members collection is empty, return 0 to indicate no members beyond the owner.
    if (membersSnapshot.size == 0) {
      return 1;
    }

    // Otherwise, return the size of the members collection.
    return membersSnapshot.size;
  } catch (e) {
    print('Error fetching member count for club $clubId: $e');
    return 1; // Default to 1 if an error occurs.
  }
  }

  void filterClubs(String query) {
    List<Club> searchResults = [];
    if (query.isNotEmpty) {
      searchResults = clubs
          .where(
              (club) => club.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      searchResults = clubs;
    }
    setState(() {
      filteredClubs = searchResults;
    });
  }

  // Function to build club cards with tap functionality
  Widget buildClubCard(Club club) {
    return GestureDetector(
      onTap: () {
        print('Tapped on club: ${club.name}');
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
          mainAxisSize: MainAxisSize.min, // Use min to prevent overflow
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
                            height: 120,
                            width: double.infinity,
                            color: Colors.red,
                            child: const Icon(Icons.error, color: Colors.white),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
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
            const SizedBox(height: 4),
            // Use Flexible here to handle overflow
            Flexible(
              child: Text(
                club.name,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1, // Limits to 1 line
                overflow:
                    TextOverflow.ellipsis, // Adds "..." if the text is too long
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${club.memberCount} members',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
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
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color(0xFFF8F8F3),
      body: isLoading // Conditional rendering based on loading state
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search for a club',
                      labelStyle:
                          TextStyle(color: Colors.grey[600], fontSize: 16),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 20.0),
                    ),
                    onChanged: (String value) {
                      filterClubs(value);
                    },
                  ),
                ),

                // List of clubs
                Expanded(
                  child: filteredClubs.isEmpty
                      ? Center(
                          child: Text(
                            'No clubs found for your search.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: filteredClubs.length,
                          itemBuilder: (context, index) {
                            return buildClubCard(filteredClubs[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: ClipOval(
        child: SizedBox(
          width: 70, // Set the width to make it bigger
          height: 70, // Set the height to make it bigger
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreateClubPage(), // Navigate to the Create Club page
                ),
              );
            },
            backgroundColor:
                const Color(0xFFF790AD), // Set the background color to pink
            child: const Icon(
              Icons.add, // Use the add icon
              color: Colors.white, // Set the icon color to white for contrast
              size: 50, // Optional: Increase the icon size
            ),
          ),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Positioning
    );
  }
}
