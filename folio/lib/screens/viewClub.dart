// view_club.dart

import 'dart:math';
import 'package:folio/screens/MemberListPage.dart';
import 'package:folio/view/callPage.dart';
import 'package:uuid/uuid.dart'; // Import UUID package
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:folio/screens/editClub.dart';
import 'package:intl/intl.dart';

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
  String _clubDiscussionDate = 'No discussion scheduled yet';
  bool _isLoading = true;
  bool _isOwner = false; // Flag to track if current user is the owner
  bool _isMember = false; // Flag to track if the user is a club member
  DateTime? _discussionDate; // To store the actual DateTime
  bool _isDiscussionScheduled = false; // To track if a discussion is scheduled
  final Uuid uuid = Uuid(); // Initialize UUID generator
  String _callID = ''; // Newly added state variable

  @override
  void initState() {
    super.initState();
    _fetchClubData();
    _checkMembership();
  }

  // Generate a unique callID using UUID
  String _generateCallID() {
    return uuid.v4();
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

        // Parse the discussion date and handle callID
        if (clubData['discussionDate'] != null) {
          _discussionDate = (clubData['discussionDate'] as Timestamp).toDate();
          _isDiscussionScheduled = true;

          // Check if callID exists
          if (clubData['callID'] != null &&
              clubData['callID'].toString().isNotEmpty) {
            _callID = clubData['callID'];
          } else {
            // Generate a new callID and store it in Firestore
            _callID = _generateCallID();
            await FirebaseFirestore.instance
                .collection('clubs')
                .doc(widget.clubId)
                .update({'callID': _callID});
          }

          _clubDiscussionDate =
              DateFormat.yMMMd().add_jm().format(_discussionDate!.toLocal());
        } else {
          _discussionDate = null;
          _isDiscussionScheduled = false;
          _clubDiscussionDate = 'No discussion scheduled yet';
          _callID = ''; // Reset callID when no discussion is scheduled
        }

        setState(() {
          _name = clubData['name'] ?? 'No Name Available';
          _clubDescription =
              clubData['description'] ?? 'No Description Available';
          _picture = clubData['picture'] ?? '';
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
      final readerDoc = await FirebaseFirestore.instance
          .collection('reader')
          .doc(ownerID)
          .get();

      if (readerDoc.exists) {
        final readerData = readerDoc.data()!;
        setState(() {
          _clubOwnerName = readerData['username'] ?? 'Unknown Owner';
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
          color: const Color(0xFFF790AD).withOpacity(0.9), // Pinkish background with opacity
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
              isJoining
                  ? 'Are you sure you want to join the club?'
                  : 'Are you sure you want to leave the club?',
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
                    backgroundColor: isJoining
                        ? const Color.fromARGB(255, 131, 201, 133) // Green for join
                        : const Color.fromARGB(255, 245, 114, 105), // Red for leave
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: const Size(100, 40), // Set button width and height
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    if (isJoining) {
                      _joinClub(); // Join the club if confirmed
                      _showConfirmationMessageJoinClub();
                    } else {
                      _leaveClub(); // Leave the club if confirmed
                      _showConfirmationMessageLeaveClub();
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
                    backgroundColor: const Color.fromARGB(255, 160, 160, 160), // Grey for "No" button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: const Size(100, 40), // Set button width and height
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


  void _showConfirmationMessageJoinClub() {
    showDialog(
      context: context,
      barrierDismissible: false, // Disable dismissal by clicking outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.lightGreen.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                'Successfully Joined Club!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    // Automatically close the confirmation dialog after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close the confirmation dialog
    });
  }

  void _showConfirmationMessageLeaveClub() {
    showDialog(
      context: context,
      barrierDismissible: false, // Disable dismissal by clicking outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.lightGreen.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                'Successfully Left Club!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    // Automatically close the confirmation dialog after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close the confirmation dialog
    });
  }

  // **New Method Added Below**
  void _showCloseMeetingConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false, // Disable dismissal by clicking outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF790AD)
                .withOpacity(0.9), // Pinkish background with opacity
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.meeting_room, // Icon for closing meeting
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to end this meeting?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center the buttons
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 245, 114, 105), // Yes button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize:
                          const Size(100, 40), // Set button width and height
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      _closeMeeting(); // End the meeting if confirmed
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
                      backgroundColor: const Color.fromARGB(
                          255, 131, 201, 133), // No button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize:
                          const Size(100, 40), // Set button width and height
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // Close the dialog without action
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
  // **End of New Method**

  void _showConfirmationMessageCloseMeeting() {
    showDialog(
      context: context,
      barrierDismissible: false, // Disable dismissal by clicking outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.lightGreen.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                'Meeting Ended Successfully!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    // Automatically close the confirmation dialog after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close the confirmation dialog
    });
  }

 Future<void> _joinClub() async {
  try {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Reference to the club's members subcollection
    var clubRef = FirebaseFirestore.instance.collection('clubs').doc(widget.clubId);

    // Check if the owner is already in the members subcollection
    var clubData = await clubRef.get();
    String ownerID = clubData['ownerID'];

    var ownerDoc = await clubRef.collection('members').doc(ownerID).get();
    
    if (!ownerDoc.exists) {
      // Add the owner to the members subcollection if not already present
      await clubRef.collection('members').doc(ownerID).set({
        'joinedAt': FieldValue.serverTimestamp(),
      });
    }

    // Add the current user as a member
    await clubRef.collection('members').doc(currentUserId).set({
      'joinedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _isMember = true;
    });

    
  } catch (e) {
    print('Error joining club: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to join the club. Please try again.')),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to leave the club. Please try again.')),
      );
    }
  }

  void _closeMeeting() async {
    try {
      // Update the club document to indicate the meeting is closed
      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.clubId)
          .update({
        'discussionDate': null, // Clear the discussion date
        'callID': FieldValue.delete(), // Remove the callID field
      });

      setState(() {
        _clubDiscussionDate = 'No discussion scheduled yet';
        _discussionDate = null; // Clear the DateTime
        _isDiscussionScheduled = false;
        _callID = ''; // Clear the stored callID
      });

      _showConfirmationMessageCloseMeeting();
    } catch (e) {
      print('Error closing meeting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to close the meeting. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the discussion date has been reached
    bool isDiscussionDateReached = _discussionDate != null &&
        DateTime.now().isAfter(_discussionDate!.toLocal());

    // Determine if the "Join Discussion" button should be visible and enabled
    bool canJoinDiscussion = (_isMember || _isOwner) && isDiscussionDateReached;

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
          if (_isOwner) // Show edit icon only if the current user is the owner
            Container(
              margin: const EdgeInsets.only(right: 30),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF4A2E2A)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditClub(
                          clubId: widget.clubId), // Pass the clubId to EditClub
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
                              child: const Center(
                                  child: Text('No Image Available')),
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
                              _clubOwnerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Dynamic member count
                        // Dynamic member count
FutureBuilder<QuerySnapshot>(
  future: FirebaseFirestore.instance
      .collection('clubs')
      .doc(widget.clubId)
      .collection('members')
      .get(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return const Text(
        'Members',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
          decoration: TextDecoration.underline,
        ),
      );
    }

    // Determine the member count, starting from 1 if the actual count is 0
    final memberCount = snapshot.data!.docs.isEmpty ? 1 : snapshot.data!.docs.length;

    return GestureDetector(
      onTap: () {
        // Check if clubID and ownerID are valid
        if (widget.clubId.isNotEmpty && _clubOwnerID.isNotEmpty) {
          // Navigate to the MemberListPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemberListPage(
                clubID: widget.clubId,
                ownerID: _clubOwnerID,
              ),
            ),
          );
        } else {
          // Handle the error appropriately, e.g., show a snackbar or log the issue
          print('Club ID or Owner ID is empty.');
        }
      },
      child: Text(
        '$memberCount Member${memberCount > 1 ? 's' : ''}', // Handle pluralization
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  },
)
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 16),
                    // Currently reading book section
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
                        Expanded(
                          // To prevent overflow
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'The Sum of All Things', // Replace with actual book title
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A2E2A),
                                ),
                              ),
                              const SizedBox(height: 4),
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 16),
                    // Join Discussion Button and Close Meeting Button
                    Row(
                      children: [
                        // Join Discussion Button
                        ElevatedButton(
                          onPressed: canJoinDiscussion
                              ? () {
                                  if (_callID.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CallPage(
                                          callID:
                                              _callID, // Use the stored callID
                                          userId: FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid, // Pass the current user's UID
                                        ),
                                      ),
                                    );
                                  } else {
                                    // Handle the case where callID is missing
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Call ID is not available. Please try again later.')),
                                    );
                                  }
                                }
                              : null, // Disable if discussion date is not reached
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFF790AD), // Button color
                          ),
                          child: const Text(
                            "Join Meeting",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Close Meeting Button (Visible only to Owner)
                        if (_isOwner && _isDiscussionScheduled)
                          ElevatedButton(
                            onPressed:
                                _showCloseMeetingConfirmation, // Trigger the new confirmation dialog
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors
                                  .red, // Red button for closing the meeting
                            ),
                            child: const Text(
                              'Close Meeting',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 16),
                    // Only show the Join/Leave button for non-owners
                    if (!_isOwner)
                      _isMember
                          ? ElevatedButton(
                              onPressed: () {
                                _showJoinLeaveConfirmation(false);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 245,
                                    114, 105), // Button color for leaving
                              ),
                              child: const Text(
                                "Leave Club",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                _showJoinLeaveConfirmation(true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 131,
                                    201, 133), // Button color for joining
                              ),
                              child: const Text(
                                "Join Club",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
