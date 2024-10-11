// view_club.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewClub extends StatefulWidget {
  final String clubId; // Add clubId as a parameter

  const ViewClub({Key? key, required this.clubId}) : super(key: key);

  @override
  _ViewClubState createState() => _ViewClubState();
}

class _ViewClubState extends State<ViewClub> {
  String _name = '';
  String _clubDescription = '';
  String _picture = '';
  String _clubOwnerID = '';
  String _clubOwnerName = 'Unknown Owner';
  String _clubDiscussionDate = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClubData();
  }

  Future<void> _fetchClubData() async {
    try {
      // Fetch the club data using the passed clubId
      final clubDoc = await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.clubId)
          .get();

      if (clubDoc.exists) {
        final clubData = clubDoc.data()!;
        _clubOwnerID = clubData['ownerID'] ?? '';
        print('Fetched ownerID: $_clubOwnerID');

        // Fetch the owner's name
        await _fetchOwnerName(_clubOwnerID);

        setState(() {
          _name = clubData['name'] ?? 'No Name Available';
          _clubDescription = clubData['description'] ?? 'No Description Available';
          _picture = clubData['picture'] ?? '';
          _clubDiscussionDate = clubData['discussionDate'] ?? '-';
          _isLoading = false;
        });
      } else {
        print('Club document does not exist.');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching club data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchOwnerName(String ownerID) async {
    try {
      print('Attempting to fetch owner name for ownerID: $ownerID');

      final ownerDoc = await FirebaseFirestore.instance
          .collection('readers')
          .doc(ownerID) // Assuming ownerID is the document ID
          .get();

      if (ownerDoc.exists) {
        final ownerData = ownerDoc.data()!;
        print('Owner document data: $ownerData');

        setState(() {
          _clubOwnerName = ownerData['name'] ?? 'Unknown Owner';
        });
      } else {
        print('Owner document does not exist.');
        setState(() {
          _clubOwnerName = 'Unknown Owner';
        });
      }
    } catch (e) {
      print('Error fetching owner name: $e');
      setState(() {
        _clubOwnerName = 'Unknown Owner';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: Color(0xFFF8F5F0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF4A2E2A)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 30),
            child: Icon(Icons.edit, color: Color(0xFF4A2E2A)),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Club picture
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: _picture.isNotEmpty
                          ? Image.network(
                              _picture,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.grey,
                              child: Center(child: Text('No Image Available')),
                            ),
                    ),
                    SizedBox(height: 16),
                    // Club name
                    Text(
                      _name,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A2E2A),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Club description
                    Text(
                      _clubDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A2E2A),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Club owner and members
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: 20,
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Created by',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              _clubOwnerName, // Display the owner's name
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        Text(
                          '15 Members', // You can update with the actual number of members
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Divider(color: Colors.grey),
                    SizedBox(height: 16),
                    // Current reading book section
                    Text(
                      'Currently reading',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A2E2A),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            width: 80,
                            height: 120,
                            color: Colors.grey,
                            child: Center(child: Text('No Image')),
                          ),
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'The sum of all things', // Replace with actual book title if available via _currentBookID
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A2E2A),
                              ),
                            ),
                            Text(
                              'Nicole Brooks', // Replace with actual author if available
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Next discussion date',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4A2E2A),
                              ),
                            ),
                            Text(
                              _clubDiscussionDate, // Discussion date from Firestore
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
