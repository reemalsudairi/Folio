import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:folio/screens/OtherProfile/otherprofile.dart';

class SearchMembersPage extends StatefulWidget {
  @override
  _SearchMembersPageState createState() => _SearchMembersPageState();
}

class _SearchMembersPageState extends State<SearchMembersPage> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  // Function to perform search based on the search query
  void _searchMembers() async {
    final query = _searchController.text.trim();

    if (query.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('reader')
            .where('username', isGreaterThanOrEqualTo: query)
            .where('username', isLessThanOrEqualTo: query + '\uf8ff')
            .get();

        setState(() {
          _searchResults = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'username': data['username'],
              'profilePhoto': data['profilePhoto'] ?? '', // Handle null case
              'name': data['name'] ?? '', // Optionally include name
            };
          }).toList();
        });
      } catch (e) {
        print('Error retrieving members: $e');
        // Optionally show an error message to the user
      }
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Members'),
        backgroundColor: Color(0xFFF8F8F3),
      ),
       backgroundColor: Color(0xFFF8F8F3),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar with updated design
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search for a member',
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
                onChanged: (value) {
                  _searchMembers(); // Call search on text change
                },
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(child: Text('No results found'))
                  : ListView.builder(
                     itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final member = _searchResults[index];
                         return GestureDetector(
                          onTap: () {
                            // Navigate to OtherProfile page with member id
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OtherProfile(memberId: member['id']),
                              ),
                            );
                          },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30.0,
                                backgroundImage: member['profilePhoto'].isNotEmpty
                                    ? NetworkImage(member['profilePhoto'])
                                    : AssetImage('assets/images/profile_pic.png') as ImageProvider,
                              ),
                              SizedBox(width: 16.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    member['username'],
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                         );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

