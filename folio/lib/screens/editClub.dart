import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditClub extends StatefulWidget {
  final String clubId;

  const EditClub({Key? key, required this.clubId}) : super(key: key);

  @override
  _EditClubState createState() => _EditClubState();
}

class _EditClubState extends State<EditClub> {
  String _name = '';
  String _clubDescription = '';
  String _picture = '';
  String _clubDiscussionDate = '';
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchClubData();
  }

  Future<void> _fetchClubData() async {
    try {
      final clubDoc = await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.clubId)
          .get();

      if (clubDoc.exists) {
        final clubData = clubDoc.data()!;

        setState(() {
          _name = clubData['name'] ?? 'No Name Available';
          _clubDescription = clubData['description'] ?? 'No Description Available';
          _picture = clubData['picture'] ?? '';
          _clubDiscussionDate = clubData['discussionDate'] ?? '-';
          _isLoading = false;

          _nameController.text = _name;
          _descriptionController.text = _clubDescription;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.clubId)
          .update({
        'name': _nameController.text,
        'description': _descriptionController.text,
        // Add any other fields to update here
      });

      Navigator.pop(context); // Return to the previous page after saving
    } catch (e) {
      print('Error saving changes: $e');
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
          IconButton(
            icon: Icon(Icons.check, color: Color(0xFF4A2E2A)), // Save button
            onPressed: _saveChanges,
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
                    // Club picture, name, description with editable fields
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Club Name'),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Club Description'),
                      maxLines: 3,
                    ),
                    // Other club details and fields
                  ],
                ),
              ),
            ),
    );
  }
}
