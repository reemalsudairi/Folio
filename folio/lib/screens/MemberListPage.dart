import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/OtherProfile/otherprofile.dart';

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

@override
Widget _buildMemberList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.clubID)
        .collection('members')
        .snapshots(),
    builder: (context, memberSnapshot) {
      if (memberSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final members = memberSnapshot.data?.docs ?? [];

      // Check if members exist
      if (members.isEmpty) {
        return const Center(child: Text('No members found.'));
      }

      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reader')
            .doc(widget.ownerID)
            .snapshots(),
        builder: (context, ownerSnapshot) {
          if (ownerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!ownerSnapshot.hasData || !ownerSnapshot.data!.exists) {
            return const Center(child: Text('Owner not found.'));
          }

          final ownerData = ownerSnapshot.data!.data() as Map<String, dynamic>?;

          if (ownerData == null) {
            return const Center(child: Text('Owner data not available.'));
          }

          String ownerName = ownerData['name'] ?? 'No Name';
          String ownerUsername = ownerData['username'] ?? 'No Username';
          String ownerProfilePhoto = ownerData['profilePhoto'] ?? '';

          return ListView(
            children: [
              // Display the owner's profile separately
              ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: (ownerProfilePhoto.isNotEmpty)
                      ? NetworkImage(ownerProfilePhoto)
                      : const AssetImage('assets/images/profile_pic.png') as ImageProvider,
                ),
                title: Text('$ownerName (Owner)'),
                subtitle: Text('@$ownerUsername'),
                onTap: () {
                  // Navigate to the OtherProfile page for the owner
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OtherProfile(
                        memberId: widget.ownerID, // Pass the owner ID to OtherProfile
                        
                      ),
                    ),
                  );
                },
              ),
              const Divider(), // Add a divider between the owner and members

              // Display the members (excluding the owner)
              ...members.where((member) => member.id != widget.ownerID).map((member) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('reader')
                      .doc(member.id)
                      .get(), // Fetch member data
                  builder: (context, memberSnapshot) {
                    if (memberSnapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink(); // Don't display until data is ready
                    }

                    if (!memberSnapshot.hasData || !memberSnapshot.data!.exists) {
                      return const SizedBox.shrink(); // Skip if no data
                    }

                    final memberData = memberSnapshot.data!.data() as Map<String, dynamic>?;

                    if (memberData == null) {
                      return const SizedBox.shrink(); // Skip if data is null
                    }

                    String memberName = memberData['name'] ?? 'No Name';
                    String memberUsername = memberData['username'] ?? 'No Username';
                    String memberProfilePhoto = memberData['profilePhoto'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: (memberProfilePhoto.isNotEmpty)
                            ? NetworkImage(memberProfilePhoto)
                            : const AssetImage('assets/images/profile_pic.png') as ImageProvider,
                      ),
                      title: Text(memberName),
                      subtitle: Text('@$memberUsername'),
                      trailing: (widget.ownerID == currentUserID)
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _showRemoveConfirmation(member.id, memberName),
                            )
                          : null,
                      onTap: () {
                        // Navigate to the OtherProfile page for the member
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherProfile(
                              memberId: member.id, // Pass the member ID to OtherProfile
                              
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }).toList(),
            ],
          );
        },
      );
    },
  );
}






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      appBar: AppBar(
      backgroundColor: Colors.transparent, // Set the AppBar background to transparent
      elevation: 0, // Remove shadow
      centerTitle: true,
      title: const Text(
        'Members',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 26,
          color: Color(0xFF351F1F), // Set the title color
        ),
      ),
    ),
      body: _buildMemberList(),
    );
  }
}