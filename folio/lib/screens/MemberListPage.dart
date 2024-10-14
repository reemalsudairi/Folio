import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MemberListPage extends StatefulWidget {
  final String clubID;
  final String ownerID; // ID of the club owner

  const MemberListPage({Key? key, required this.clubID, required this.ownerID})
      : super(key: key);

  @override
  _MemberListPageState createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> {
  late String currentUserID;

  @override
  void initState() {
    super.initState();

    // Fetch the current user ID from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserID = user.uid; // Set the current user ID
    }
  }

  // Function to show the confirmation dialog
  void _showRemoveConfirmation(String memberID, String memberName) {
    showDialog(
      context: context,
      barrierDismissible: false, // Disable dismissal by clicking outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF790AD).withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.exit_to_app,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to remove $memberName?',
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
                      backgroundColor: const Color.fromARGB(255, 245, 114, 105),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: const Size(100, 40),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      _removeMember(memberID, memberName); // Remove the member if confirmed
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
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: const Size(100, 40),
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

  // Function to remove the member from the Firebase database
  void _removeMember(String memberID, String memberName) async {
    try {
      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.clubID)
          .collection('members')
          .doc(memberID)
          .delete();
      _showConfirmationMessage(memberName); // Show success message with member name
    } catch (e) {
      print('Error removing member: $e');
    }
  }

  // Function to show the "Member Removed Successfully!" message
  void _showConfirmationMessage(String memberName) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                '$memberName Removed Successfully!',
                style: const TextStyle(
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

  // Function to build the member list
  Widget _buildMemberList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.clubID)
          .collection('members')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Handle the case where there are no members except for the owner
          return ListView(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reader')
                    .doc(widget.ownerID)
                    .snapshots(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> ownerSnapshot) {
                  if (ownerSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }

                  if (!ownerSnapshot.hasData || !ownerSnapshot.data!.exists) {
                    return const ListTile(
                      title: Text('Owner not found.'),
                    );
                  }

                  var ownerData =
                      ownerSnapshot.data!.data() as Map<String, dynamic>;
                  String ownerName = ownerData['name'] ?? 'No Name';
                  String ownerUsername = ownerData['username'] ?? 'No Username';
                  String profilePhoto =
                      ownerData['profilePhoto'] ?? ''; // Default if not found

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profilePhoto.isNotEmpty
                          ? NetworkImage(profilePhoto)
                          : const AssetImage('assets/profile_pic.png')
                              as ImageProvider,
                    ),
                    title: Text('$ownerName (Owner)'),
                    subtitle: Text('@$ownerUsername'),
                    // No trailing button for the owner
                  );
                },
              ),
            ],
          );
        }

        List<QueryDocumentSnapshot> members = snapshot.data!.docs;

        // Separate the owner from other members
        QueryDocumentSnapshot? ownerDoc;
        List<QueryDocumentSnapshot> otherMembers = [];

        for (var member in members) {
          if (member.id == widget.ownerID) {
            ownerDoc = member;
          } else {
            otherMembers.add(member);
          }
        }

        // Display the owner at the top and other members
        return ListView.builder(
          itemCount: otherMembers.length + 1, // +1 for the owner
          itemBuilder: (context, index) {
            if (index == 0 && ownerDoc != null) {
              // Display the owner first
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reader')
                    .doc(widget.ownerID)
                    .snapshots(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> ownerSnapshot) {
                  if (ownerSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }

                  if (!ownerSnapshot.hasData || !ownerSnapshot.data!.exists) {
                    return const ListTile(
                      title: Text('Owner not found.'),
                    );
                  }

                  var ownerData =
                      ownerSnapshot.data!.data() as Map<String, dynamic>;
                  String ownerName = ownerData['name'] ?? 'No Name';
                  String ownerUsername = ownerData['username'] ?? 'No Username';
                  String profilePhoto =
                      ownerData['profilePhoto'] ?? 'assets/profile_pic.png'; // Default if not found

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profilePhoto.isNotEmpty
                          ? NetworkImage(profilePhoto)
                          : const AssetImage('assets/profile_pic.png')
                              as ImageProvider,
                    ),
                    title: Text('$ownerName (Owner)'),
                    subtitle: Text('@$ownerUsername'),
                    // No trailing button for the owner
                  );
                },
              );
            }

            // For other members
            var member = otherMembers[index - 1]; // Adjust for owner at index 0
            String memberID = member.id;

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reader')
                  .doc(memberID)
                  .snapshots(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> memberSnapshot) {
                if (memberSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    title: Text('Loading...'),
                  );
                }

                if (!memberSnapshot.hasData || !memberSnapshot.data!.exists) {
                  return const ListTile(
                    title: Text('Member not found.'),
                  );
                }

                var memberData =
                    memberSnapshot.data!.data() as Map<String, dynamic>;
                String memberName = memberData['name'] ?? 'No Name';
                String memberUsername = memberData['username'] ?? 'No Username';
                String profilePhoto =
                    memberData['profilePhoto'] ?? 'assets/profile_pic.png'; // Default if not found

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: profilePhoto.isNotEmpty
                        ? NetworkImage(profilePhoto)
                        : const AssetImage('assets/profile_pic.png')
                            as ImageProvider,
                  ),
                  title: Text(memberName),
                  subtitle: Text('@$memberUsername'),
                  trailing: currentUserID == widget.ownerID // Only show for owner
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            _showRemoveConfirmation(memberID, memberName); // Show confirmation dialog
                          },
                        )
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member List'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous page
          },
        ),
      ),
      body: _buildMemberList(),
    );
  }
}
