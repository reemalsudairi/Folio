import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:folio/services/local.notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClubListener {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Timer? _timer;
  bool _notificationsEnabled = true;
  ClubListener() {
    // Initialize local notifications
    _initializeNotifications();

    // Listen for authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null || _notificationsEnabled) {
        // User signed out, cancel notifications and stop timer
        cancelAllNotifications();
        _timer?.cancel();
        _timer = null;
        log('User signed out: Notifications and timer stopped.');
      } else {
        // User signed in, start periodic checks
        log('User signed in: Starting periodic checks.');
        _startPeriodicChecks();
      }
    });

    log('ClubListener initialized');
  }

  // Initialize the local notifications plugin
  void _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Start a periodic timer to check club members every 30 seconds
  void _startPeriodicChecks() {
    if (!_notificationsEnabled) {
      log('Notifications disabled: Skipping checks.');
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      log('Performing periodic club member checks...');
      if (_isUserSignedIn() && _notificationsEnabled) {
        await _fetchClubsAndCheckMembers();
      } else {
        log('User is signed out. Skipping notifications.');
      }
    });
  }

  // Check if the user is signed in
  bool _isUserSignedIn() {
    final User? user = FirebaseAuth.instance.currentUser;
    return user != null;
  }

  // Fetch clubs and check for notifications
  Future<void> _fetchClubsAndCheckMembers() async {
    try {
      final clubsSnapshot = await _firestore.collection('clubs').get();

      for (var clubDoc in clubsSnapshot.docs) {
        await _handleClubUpdate(clubDoc);
      }
    } catch (e) {
      log('Error fetching clubs: $e');
    }
  }

  // Handle club update by checking the discussion date
  Future<void> _handleClubUpdate(DocumentSnapshot clubDoc) async {
    try {
      log('Handling club update for club: ${clubDoc.id}');

      var clubData = clubDoc.data() as Map<String, dynamic>;
      if (clubData == null) {
        log('Club data is null for club: ${clubDoc.id}');
        return;
      }

      if (clubData['discussionDate'] == null) {
        log('No discussionDate found for club: ${clubDoc.id}');
        return;
      }

      DateTime discussionDate =
          (clubData['discussionDate'] as Timestamp).toDate();
      DateTime currentDate = DateTime.now();

      if (currentDate.isBefore(discussionDate) ||
          currentDate.difference(discussionDate).inSeconds.abs() <= 60) {
        log('Discussion time reached or close for club: ${clubDoc.id}');
        await _scheduleNotificationsForMembers(clubDoc.id, discussionDate);
      } else {
        log('Discussion time not reached or passed for club: ${clubDoc.id}');
      }
    } catch (e, stackTrace) {
      log('Error handling club update for club: ${clubDoc.id}',
          error: e, stackTrace: stackTrace);
    }
  }

// Schedule notifications for all members of the club
  Future<void> _scheduleNotificationsForMembers(
      String clubId, DateTime discussionDate) async {
    try {
      // Fetch the club details
      final clubSnapshot =
          await _firestore.collection('clubs').doc(clubId).get();

      if (!clubSnapshot.exists) {
        log('Club data not found for clubId: $clubId');
        return;
      }

      var clubData = clubSnapshot.data() as Map<String, dynamic>;
      String clubName = clubData['name'] ?? 'your club';

      // Get the list of members
      final membersSnapshot = await _firestore
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .get();

      for (var memberDoc in membersSnapshot.docs) {
        String memberId = memberDoc.id;

        // Fetch the member's details
        final memberSnapshot =
            await _firestore.collection('reader').doc(memberId).get();

        if (memberSnapshot.exists) {
          var memberData = memberSnapshot.data() as Map<String, dynamic>;
          String memberName = memberData['username'] ?? 'User';

          // Only schedule notifications for the currently logged-in member
          if (FirebaseAuth.instance.currentUser?.uid == memberId) {
            log('Scheduling notification for member: $memberId ($memberName)');

            // Schedule the notification
            await _scheduleNotificationForMember(
              memberId,
              'Discussion Reminder',
              'Hi $memberName, the club "$clubName" discussion has now started.',
              discussionDate,
            );

            // Store the notification in the member's sub-collection
            await _storeNotificationForMember(
              memberId,
              'Discussion Reminder',
              'Hi $memberName, the club "$clubName" discussion has now started.',
              discussionDate,
            );
          } else {
            log('Skipping notification for non-logged-in member: $memberId');
          }
        } else {
          log('Member data not found for memberId: $memberId');
        }
      }
    } catch (e) {
      log('Error scheduling notifications for members: $e');
    }
  }

  // Schedule a notification for a specific member
  Future<void> _scheduleNotificationForMember(String memberId, String title,
      String body, DateTime scheduledTime) async {
    if (!_isUserSignedIn()) {
      log('User is signed out. Skipping notification for member $memberId.');
      return;
    }

    LocalNotificationService.showScheduledNotification(
      id: memberId.hashCode,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    );
  }

  // Cancel the timer when no longer needed
  void dispose() {
    _timer?.cancel();
    log('Periodic checks stopped.');
  }

  Future<void> _storeNotificationForMember(String memberId, String title,
      String body, DateTime scheduledTime) async {
    try {
      // Query the notifications sub-collection to check if a notification already exists for the given time
      final notificationsSnapshot = await _firestore
          .collection('reader')
          .doc(memberId)
          .collection('notifications')
          .where('scheduledTime', isEqualTo: scheduledTime)
          .get();

      // If no notification exists with the same scheduled time, store the new notification
      if (notificationsSnapshot.docs.isEmpty) {
        final notificationData = {
          'title': title,
          'body': body,
          'scheduledTime': scheduledTime,
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Store the notification in the 'notifications' sub-collection under the member's document
        await _firestore
            .collection('reader')
            .doc(memberId)
            .collection('notifications')
            .add(notificationData);

        log('Notification stored for member: $memberId');
      } else {
        log('Notification already exists for member: $memberId at this scheduled time.');
      }
    } catch (e) {
      log('Error storing notification for member: $memberId - $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    log('All scheduled notifications have been canceled.');
  }

  void toggleNotifications(bool enable) async {
    _notificationsEnabled = enable;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enable);

    if (enable) {
      log('Notifications enabled: Starting periodic checks.');
      _startPeriodicChecks();
    } else {
      log('Notifications disabled: Stopping periodic checks and clearing notifications.');
      cancelAllNotifications();
      _timer?.cancel();
    }
  }
}
