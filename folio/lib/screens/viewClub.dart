import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/MemberListPage.dart';
import 'package:folio/screens/book_details_page.dart';
import 'package:folio/screens/editClub.dart';
import 'package:folio/view/callPage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // Import UUID package

class ViewClub extends StatefulWidget {
  final String clubId;
  final bool fromCreate;

  ViewClub({Key? key, required this.clubId, this.fromCreate = false}) : super(key: key);

  @override
  _ViewClubState createState() => _ViewClubState();
}

Future _fetchBookData(String clubId) async {
  final bookDataRef =
      FirebaseFirestore.instance.collection('clubs').doc(clubId);
  final bookDataSnapshot = await bookDataRef.get();
  if (bookDataSnapshot.exists) {
    final clubData = bookDataSnapshot.data() as Map<String, dynamic>;

    // Fetch book details from Google Books API
    if (clubData['currentBookID'] != null) {
      final bookResponse = await http.get(Uri.parse(
          'https://www.googleapis.com/books/v1/volumes/${clubData['currentBookID']}'));
      if (bookResponse.statusCode == 200) {
        final bookData = jsonDecode(bookResponse.body);
        return {
          'bookID': clubData['currentBookID'], // Fetch the book ID
          'title': bookData['volumeInfo']['title'] ?? '',
          'author': bookData['volumeInfo']['authors']?[0] ?? '',
          'image': bookData['volumeInfo']['imageLinks']['thumbnail'] ?? '',
        };
      } else {
        print('Failed to retrieve book details from Google Books API');
      }
    }
  }
  return null;
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
  String _clubOwnerProfilePhoto = '';
  String _language = '';

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
          _language = clubData['language'] ?? 'Unknown Language';
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
          _clubOwnerProfilePhoto = readerData['profilePhoto'] ??
              ''; // Fetch the owner's profile picture
        });
      } else {
        setState(() {
          _clubOwnerName = 'Unknown Owner';
          _clubOwnerProfilePhoto =
              ''; // Initialize the profile picture to an empty string
        });
      }
    } catch (e) {
      setState(() {
        _clubOwnerName = 'Unknown Owner';
        _clubOwnerProfilePhoto =
            ''; // Initialize the profile picture to an empty string
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
            color: const Color(0xFFF790AD)
                .withOpacity(0.9), // Pinkish background with opacity
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isJoining
                    ? Icons.group_add
                    : Icons.exit_to_app, // Icon changes based on action
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
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center the buttons
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isJoining
                          ? const Color.fromARGB(
                              255, 131, 201, 133) // Green for join
                          : const Color.fromARGB(
                              255, 245, 114, 105), // Red for leave
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize:
                          const Size(100, 40), // Set button width and height
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
                      backgroundColor: const Color.fromARGB(
                          255, 160, 160, 160), // Grey for "No" button
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
                      backgroundColor: Colors.grey, // No button color
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
      var clubRef =
          FirebaseFirestore.instance.collection('clubs').doc(widget.clubId);

      // Check the club data
      var clubData = await clubRef.get();
      String ownerID = clubData['ownerID'];

      // Add the owner to the members subcollection if not already present
      var ownerDoc = await clubRef.collection('members').doc(ownerID).get();
      if (!ownerDoc.exists) {
        var ownerData = await FirebaseFirestore.instance
            .collection('reader')
            .doc(ownerID)
            .get();
        if (ownerData.exists) {
          String ownerName = ownerData['name'] ?? 'No Name';
          String ownerUsername = ownerData['username'] ?? 'No Username';
          String ownerProfilePhoto = ownerData['profilePhoto'] ??
              'assets/profile_pic.png'; // Default profile picture

          // Add the owner to the members subcollection
          await clubRef.collection('members').doc(ownerID).set({
            'joinedAt': FieldValue.serverTimestamp(),
            'name': ownerName,
            'username': ownerUsername,
            'profilePhoto': ownerProfilePhoto,
          });
        }
      }

      // Fetch the current user's profile data
      var userDoc = await FirebaseFirestore.instance
          .collection('reader')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        var userData = userDoc.data()!;
        String name = userData['name'] ?? 'No Name';
        String username = userData['username'] ?? 'No Username';
        String profilePhoto = userData['profilePhoto'] ??
            'assets/profile_pic.png'; // Default profile picture

        // Add the current user as a member with additional information
        await clubRef.collection('members').doc(currentUserId).set({
          'joinedAt': FieldValue.serverTimestamp(),
          'name': name,
          'username': username,
          'profilePhoto': profilePhoto,
        });
      }

      setState(() {
        _isMember = true;
      });
    } catch (e) {
      print('Error joining club: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to join the club. Please try again.')),
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
  bool canJoinDiscussion = (_isMember || _isOwner) &&
      _isDiscussionScheduled &&
      isDiscussionDateReached;

  return Scaffold(
    backgroundColor: const Color(0xFFF8F5F0),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF8F5F0),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF4A2E2A)),
        onPressed: () {
          if (widget.fromCreate) {
            Navigator.pop(context);
            Navigator.pop(context);
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: const Text(
        'Club Details',
        style: TextStyle(
          color: Color(0xFF4A2E2A),
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_isOwner)
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF4A2E2A)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditClub(clubId: widget.clubId),
                ),
              ).then((_) {
                // Refresh the club data after returning from EditClub
                setState(() {
                  _isLoading = true; // Set loading state before fetching
                });
              });
            },
          ),
        const SizedBox(width: 8),
      ],
    ),
    body: StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.clubId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching club data.'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Club does not exist.'));
        }

        final clubData = snapshot.data!.data() as Map<String, dynamic>;

        // Update your state variables from clubData
        _name = clubData['name'] ?? 'No Name Available';
        _clubDescription = clubData['description'] ?? 'No Description Available';
        _picture = clubData['picture'] ?? '';
        _language = clubData['language'] ?? 'Unknown Language';
        _clubOwnerID = clubData['ownerID'] ?? '';
        
        // Continue with your existing logic to check ownership, membership, etc.
        // ...

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Club picture
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image(
                    image: _picture.isNotEmpty
                        ? NetworkImage(_picture)
                        : AssetImage('assets/images/clubs.jpg'),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                // Club name and Join/Leave button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Club name
                    Expanded(
                      child: Text(
                        _name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A2E2A),
                        ),
                      ),
                    ),
                    // Join/Leave button
                    if (!_isOwner)
                      _isMember
                          ? ElevatedButton(
                              onPressed: () {
                                _showJoinLeaveConfirmation(false);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 245, 114, 105),
                              ),
                              child: Text(
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
                                backgroundColor: Color.fromARGB(255, 131, 201, 133),
                              ),
                              child: Text(
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
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: (_clubOwnerProfilePhoto.isNotEmpty)
                              ? NetworkImage(_clubOwnerProfilePhoto)
                              : const AssetImage(
                                      'assets/images/profile_pic.png')
                                  as ImageProvider,
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
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('clubs')
                              .doc(widget.clubId)
                              .collection('members')
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
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

                            // Get the number of members
                            final memberCount = snapshot.data!.docs.length;

                            // Set display count to 1 if there are no members, otherwise display the actual count
                            final displayCount =
                                memberCount == 0 ? 1 : memberCount;

                            return GestureDetector(
                              onTap: () {
                                // Check if clubID and ownerID are valid
                                if (widget.clubId.isNotEmpty &&
                                    _clubOwnerID.isNotEmpty) {
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
                                '$displayCount Members', // Use the display count
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),

                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A2E2A),
                        ),
                        children: [
                          TextSpan(
                            text: "Club's language: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: _language),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),
                    // Currently reading book section
                    const Text(
                      'Currently reading',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A2E2A),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Currently reading book section
                    FutureBuilder(
                      future: _fetchBookData(widget.clubId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return const Text(
                            'Error fetching data',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          );
                        }

                        final bookData = snapshot.data;

                        if (bookData == null) {
                          return const Text(
                            'No book has been selected for this club.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          );
                        }

                        return Column(
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to BookDetailsPage when the book cover is tapped
                                    if (bookData['bookID'] != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookDetailsPage(
                                            bookId: bookData['bookID'],
                                            userId: FirebaseAuth
                                                .instance.currentUser!.uid,
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Book ID is not available.')),
                                      );
                                    }
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Container(
                                      width: 80,
                                      height: 120,
                                      child: bookData['image'] != null
                                          ? Image.network(
                                              bookData['image'],
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              'folio/assets/images/clubs.jpg'), // Display default image
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      // Navigate to BookDetailsPage when the book title is tapped
                                      if (bookData['bookID'] != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                BookDetailsPage(
                                              bookId: bookData['bookID'],
                                              userId: FirebaseAuth
                                                  .instance.currentUser!.uid,
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Book ID is not available.')),
                                        );
                                      }
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (bookData['title'] != null)
                                          Text(
                                            bookData['title'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4A2E2A),
                                            ),
                                          ),
                                        if (bookData['author'] != null)
                                          Text(
                                            bookData['author'],
                                            style: const TextStyle(
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
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    Divider(color: Colors.grey),
                    SizedBox(height: 5),
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
                                      SnackBar(
                                          content: Text(
                                              'Call ID is not available. Please try again later.')),
                                    );
                                  }
                                }
                              : null, // Disable if discussion date is not reached
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF790AD), // Button color
                          ),
                          child: Text(
                            "Join Meeting",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // Close Meeting Button (Visible only to Owner)
                        if (_isOwner &&
                            _isDiscussionScheduled &&
                            DateTime.now().isAfter(_discussionDate!.toLocal()))
                          ElevatedButton(
                            onPressed:
                                _showCloseMeetingConfirmation, // Trigger the new confirmation dialog
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 245, 114,
                                  105), // Red button for closing the meeting
                            ),
                            child: Text(
                              'End Meeting',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 5),

                    SizedBox(height: 5),
                    // Only show the Join/Leave button for non-owners
                    
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            
    );
      
      }));

}
}
