import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:folio/constant/callInfo.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallPage extends StatefulWidget {
  const CallPage({
    Key? key,
    required this.callID,
    required this.userId,
  }) : super(key: key);

  final String callID;
  final String userId;

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  String _userName = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      // Fetch the user's document from the 'reader' collection
      final readerDoc = await FirebaseFirestore.instance
          .collection('reader')
          .doc(widget.userId)
          .get();

      if (readerDoc.exists) {
        final readerData = readerDoc.data()!;
        setState(() {
          _userName = readerData['username'] ?? 'Unknown User';
          _isLoading = false;
        });
      } else {
        setState(() {
          _userName = 'Unknown User';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user name: $e');
      setState(() {
        _userName = 'Unknown User';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show a loading indicator while fetching the user name
      return Scaffold(
        appBar: AppBar(
          title: const Text('Joining Discussion...'),
          backgroundColor: Color(0xFFF790AD),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ZegoUIKitPrebuiltCall(
      appID: CallInfo.appId, // Replace with your actual appID
      appSign: CallInfo.appsign, // Replace with your actual appSign
      userID: widget.userId, // Use the passed userId
      userName: _userName, // Use the fetched userName
      callID: widget.callID,
      config: ZegoUIKitPrebuiltCallConfig.groupVideoCall(), // Changed to group video call
    );
  }
}
