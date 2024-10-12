/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth to check current user
import 'package:flutter/material.dart';
import 'package:folio/screens/editClub.dart';

class ViewClub extends StatefulWidget {
  final String clubId;

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
  bool _isOwner = false; // Flag to track if current user is the owner

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

        // Check if the current user is the owner
        String currentUserId = FirebaseAuth.instance.currentUser!.uid;
        _isOwner = _clubOwnerID == currentUserId;

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
      final ownerDoc = await FirebaseFirestore.instance
          .collection('readers')
          .doc(ownerID) // Assuming ownerID is the document ID
          .get();

      if (ownerDoc.exists) {
        final ownerData = ownerDoc.data()!;
        setState(() {
          _clubOwnerName = ownerData['name'] ?? 'Unknown Owner';
        });
      } else {
        setState(() {
          _clubOwnerName = 'Unknown Owner';
        });
      }
    } catch (e) {
      setState(() {
        _clubOwnerName = 'Unknown Owner';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A2E2A)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
       actions: [
  if (_isOwner) // Show pencil icon only if the current user is the owner
    Container(
      margin: const EdgeInsets.only(right: 30),
      child: IconButton(
        icon: const Icon(Icons.edit, color: Color(0xFF4A2E2A)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditClub(clubId: widget.clubId), // Pass the clubId to EditClub
            ),
          );
        },
      ),
    ),
],

      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                              child: const Center(child: Text('No Image Available')),
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Club name
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A2E2A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Club description
                    Text(
                      _clubDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A2E2A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Club owner and members
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: 20,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Created by',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              _clubOwnerName, // Display the owner's name
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          '15 Members', // Update this with the actual number of members
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 16),
                    // Current reading book section
                    const Text(
                      'Currently reading',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A2E2A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            width: 80,
                            height: 120,
                            color: Colors.grey,
                            child: const Center(child: Text('No Image')),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'The sum of all things', // Replace with actual book title
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A2E2A),
                              ),
                            ),
                            const Text(
                              'Nicole Brooks', // Replace with actual author
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Next discussion date',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4A2E2A),
                              ),
                            ),
                            Text(
                              _clubDiscussionDate, // Discussion date from Firestore
                              style: const TextStyle(
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
}*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth to check current user
import 'package:flutter/material.dart';
import 'package:folio/screens/editClub.dart';

class ViewClub extends StatefulWidget {
  final String clubId;

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
  bool _isOwner = false; // Flag to track if current user is the owner
  bool _isMember = false; // Flag to track if the user is a club member

  @override
  void initState() {
    super.initState();
    _fetchClubData();
    _checkMembership();
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

        // Check if the current user is the owner
        String currentUserId = FirebaseAuth.instance.currentUser!.uid;
        _isOwner = _clubOwnerID == currentUserId;

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
    // Query the clubs collection to find the document where 'ownerID' matches the provided ownerID
    final querySnapshot = await FirebaseFirestore.instance
        .collection('clubs')
        .where('ownerID', isEqualTo: ownerID) // Query based on the 'ownerID' field
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Get the first document that matches the query
      final ownerDoc = querySnapshot.docs.first;
      final ownerData = ownerDoc.data();
      
      // Extract the ownerID (assuming ownerID is stored correctly in the document)
      final String ownerID = ownerData['ownerID'];

      // Fetch the owner details from the 'reader' collection using the ownerID
      final readerDoc = await FirebaseFirestore.instance
          .collection('reader') // Fetch from 'reader' collection
          .doc(ownerID) // Use the ownerID as the document ID in 'reader'
          .get();

      if (readerDoc.exists) {
        final readerData = readerDoc.data()!;
        setState(() {
          _clubOwnerName = readerData['name'] ?? 'Unknown Owner';
        });
      } else {
        setState(() {
          _clubOwnerName = 'Unknown Owner';
        });
      }
    } else {
      setState(() {
        _clubOwnerName = 'Unknown Owner';
      });
    }
  } catch (e) {
    setState(() {
      _clubOwnerName = 'Unknown Owner';
    });
  }
}



  Future<void> _checkMembership() async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final memberDoc = await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.clubId)
          .collection('members')
          .doc(currentUserId)
          .get();

      setState(() {
        _isMember = memberDoc.exists;
      });
    } catch (e) {
      print('Error checking membership: $e');
    }
  }
void _showJoinLeaveConfirmation(bool isJoining) {
  showDialog(
    context: context,
    barrierDismissible: false, // Disable dismissal by clicking outside
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFFF790AD).withOpacity(0.9), // Same light green background with opacity
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isJoining ? Icons.group_add : Icons.exit_to_app, // Icon changes based on action
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              isJoining ? 'Are you sure you want to join the club?' : 'Are you sure you want to leave the club?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the buttons
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 131, 201, 133), // Yes button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: Size(100, 40), // Set button width and height
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    if (isJoining) {
                      _joinClub(); // Join the club if confirmed
                    } else {
                      _leaveClub(); // Leave the club if confirmed
                    }
                  },
                  child: const Text(
                    'Yes', 
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12), // Space between buttons
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 245, 114, 105), // No button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: Size(100, 40), // Set button width and height
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog without action
                  },
                  child: const Text(
                    'No', 
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


  Future<void> _joinClub() async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.clubId)
          .collection('members')
          .doc(currentUserId)
          .set({
        'joinedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isMember = true;
      });
    } catch (e) {
      print('Error joining club: $e');
    }
  }

  Future<void> _leaveClub() async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.clubId)
          .collection('members')
          .doc(currentUserId)
          .delete();

      setState(() {
        _isMember = false;
      });
    } catch (e) {
      print('Error leaving club: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A2E2A)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (_isOwner) // Show pencil icon only if the current user is the owner
            Container(
              margin: const EdgeInsets.only(right: 30),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF4A2E2A)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditClub(clubId: widget.clubId), // Pass the clubId to EditClub
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                              child: const Center(child: Text('No Image Available')),
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Club name
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A2E2A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Club description
                    Text(
                      _clubDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A2E2A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Club owner and members
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: 20,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Created by',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              _clubOwnerName, // Display the owner's name
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          '15 Members', // Update this with the actual number of members
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 16),
                    // Current reading book section
                    const Text(
                      'Currently reading',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A2E2A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            width: 80,
                            height: 120,
                            color: Colors.grey,
                            child: const Center(child: Text('No Image')),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'The sum of all things', // Replace with actual book title
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A2E2A),
                              ),
                            ),
                            const Text(
                              'Nicole Brooks', // Replace with actual author
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Next discussion date',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4A2E2A),
                              ),
                            ),
                            Text(
                              _clubDiscussionDate, // Discussion date from Firestore
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A2E2A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 16),
                    // Only show the Join/Leave button for non-owners
//if (!_isOwner)
  _isMember
      ? ElevatedButton(
           onPressed: () {
    _showJoinLeaveConfirmation(false); 
  },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 245, 114, 105), // Button color for leaving
          ),
          child: const Text("Leave Club",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
        )
      : ElevatedButton(
           onPressed: () {
    _showJoinLeaveConfirmation(true); // Call with `true` to join the club
  },

          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 131, 201, 133), // Button color for joining
          ),
          child: const Text("Join Club",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
        ),



                  ],
                ),
              ),
            ),
    );
  }
}

