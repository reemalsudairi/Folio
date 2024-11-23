import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpdatesNotificationBell extends StatefulWidget {
  final String currentUserId; // The logged-in user's ID

  UpdatesNotificationBell({required this.currentUserId});

  @override
  _UpdatesNotificationBellState createState() =>
      _UpdatesNotificationBellState();
}

class _UpdatesNotificationBellState extends State<UpdatesNotificationBell> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> deletedUpdateIds = []; // Track deleted update IDs

  @override
void initState() {
  super.initState();
  _setLastCheckedUpdates();  // Update the lastCheckedUpdates when the page opens
}

Future<void> _setLastCheckedUpdates() async {
  try {
    DocumentReference readerDoc = _firestore.collection('reader').doc(widget.currentUserId);

    // Set the current timestamp as the last checked updates timestamp
    await readerDoc.update({
      'lastCheckedUpdates': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print('Error setting lastCheckedUpdates: $e');
  }
}


Stream<List<Map<String, String>>> _getUpdates() {
  return _firestore
      .collection('reader')
      .doc(widget.currentUserId)
      .snapshots() // Listen to changes in the reader's document
      .asyncMap((readerSnapshot) async {
    // Safely get reader data
    if (!readerSnapshot.exists) {
      return [];
    }

    Map<String, dynamic> readerData = readerSnapshot.data() as Map<String, dynamic>;
    List<String> hiddenUpdates = List<String>.from(readerData['hiddenUpdates'] ?? []);

    // Fetch the user's clubs
    QuerySnapshot clubSnapshot = await _firestore
        .collection('clubs')
        .where('ownerID', isEqualTo: widget.currentUserId)
        .get();

    List<Map<String, String>> updates = [];

    for (var clubDoc in clubSnapshot.docs) {
      String clubName = clubDoc['name'] ?? 'Unknown Club';
      var membersSnapshot = await clubDoc.reference.collection('members').get();

      for (var doc in membersSnapshot.docs) {
        if (doc.id == widget.currentUserId) continue; // Skip the owner

        String updateKey = '${clubDoc.id}|${doc.id}';

        if (hiddenUpdates.contains(updateKey)) continue;

        updates.add({
          'message': '${doc['username'] ?? 'Unknown'} joined your club: $clubName',
          'timestamp': (doc['joinedAt'] as Timestamp?) != null
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format((doc['joinedAt'] as Timestamp).toDate())
              : 'No date available',
          'updateID': doc.id,
          'clubID': clubDoc.id,
        });
      }
    }

    return updates;
  });
}



  Future<void> _removeUpdate(String clubID, String memberID) async {
    try {
      DocumentReference readerDoc =
          _firestore.collection('reader').doc(widget.currentUserId);

      await readerDoc.update({
        'hiddenUpdates': FieldValue.arrayUnion(['$clubID|$memberID']),
      });

      setState(() {
        deletedUpdateIds
            .add('$clubID|$memberID'); // Track removed updates in UI
      });

      _showConfirmationMessage('Update');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing update: $e')),
      );
    }
  }

Future<void> _clearAllUpdates() async {
  try {
    DocumentReference readerDoc = _firestore.collection('reader').doc(widget.currentUserId);

    // Get all update keys for this user and add them to the hiddenUpdates array
    List<Map<String, String>> updates = await _getUpdates().first;
    List<String> allUpdateKeys = updates.map((update) => '${update['clubID']}|${update['updateID']}').toList();

    await readerDoc.update({
      'hiddenUpdates': FieldValue.arrayUnion(allUpdateKeys), // Add all updates to hiddenUpdates
    });

    setState(() {
      deletedUpdateIds.addAll(allUpdateKeys); // Update local state to reflect the cleared updates
    });

    _showConfirmationMessage('All updates');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error clearing updates: $e')),
    );
  }
}



  void _showRemoveUpdateConfirmation(String clubID, String memberID) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                Icons.delete_forever,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to remove this update?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      Navigator.of(context).pop();
                      _removeUpdate(clubID, memberID);
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
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: const Size(100, 40),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
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

  void _showConfirmationMessage(String updateName) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                '$updateName Removed Successfully!',
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

    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close the dialog after 2 seconds
    });
  }

  void _showClearAllUpdatesConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                Icons.delete_forever,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to clear all updates?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      Navigator.of(context).pop();
                      _clearAllUpdates();
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
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: const Size(100, 40),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Updates",
          style: TextStyle(
            color: Color(0xFF4A2E2A),
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(
            0xFFF8F5F0), // Optional: Customize AppBar background color
        actions: [
          IconButton(
            icon: Icon(
              Icons.clear_all,
              color: Color(0xFF4A2E2A), // Set color for the icon
            ),
            onPressed: _showClearAllUpdatesConfirmation,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, String>>>(
  stream: _getUpdates(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      // Handle specific errors here (e.g., null field, empty list)
      return Center(child: Text("Error loading updates: ${snapshot.error}"));
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(child: Text("No updates to display."));
    }

    List<Map<String, String>> updates = snapshot.data!;

    return ListView.builder(
      itemCount: updates.length,
      itemBuilder: (context, index) {
        var update = updates[index];
        return Card(
          child: ListTile(
            leading: Icon(Icons.notifications, color: Color(0xFFF790AD)),
            title: Text(update['message']!),
            subtitle: Text(update['timestamp']!),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _showRemoveUpdateConfirmation(update['clubID']!, update['updateID']!),
            ),
          ),
        );
      },
    );
  },
),

    );
  }
} 