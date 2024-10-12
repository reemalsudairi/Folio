import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/viewClub.dart';

class Club {
  final String id;
  final String name;
  final String picture;

  Club({required this.id, required this.name, required this.picture});

  factory Club.fromMap(Map<String, dynamic> data, String documentId) {
    return Club(
      id: documentId,
      name: data['name'] ?? '',
      picture: data['picture'] ?? '',
    );
  }
}

class Clubs extends StatelessWidget {
  const Clubs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Clubs',style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Color(0xFF351F1F),
          ),),
        backgroundColor: Color(0xFFF8F8F3),
      ),
      backgroundColor: Color(0xFFF8F8F3), // Set background color here
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

  @override
  void initState() {
    super.initState();
    fetchClubs();
  }

  Future<void> fetchClubs() async {
    try {
      QuerySnapshot clubsSnapshot =
          await FirebaseFirestore.instance.collection('clubs').get();

      setState(() {
        clubs = clubsSnapshot.docs
            .map((doc) => Club.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        filteredClubs = clubs; // Initially, show all clubs
      });
    } catch (e) {
      print('Error fetching clubs: $e');
    }
  }

  void filterClubs(String query) {
    List<Club> searchResults = [];
    if (query.isNotEmpty) {
      searchResults = clubs
          .where((club) =>
              club.name.toLowerCase().contains(query.toLowerCase()))
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
      print('Tapped on club: ${club.name}'); // Debugging line
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
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
       Padding(
  padding: const EdgeInsets.all(8.0),
  child: TextField(
    decoration: InputDecoration(
      labelText: 'Search for a club',
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
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
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }
}
