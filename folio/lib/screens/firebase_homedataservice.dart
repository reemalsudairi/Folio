import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:folio/screens/Homedataservice.dart';
import 'package:folio/screens/Profile/clubs_page.dart';
import 'package:http/http.dart' as http;
import 'package:folio/screens/Profile/book.dart';
import 'package:folio/screens/viewClub.dart';
import 'Homedataservice.dart';

class FirebaseHomeDataService implements HomeDataService {
  final _firestore = FirebaseFirestore.instance;

  @override
  Stream<UserData> getUserData(String uid) {
    return _firestore.collection('reader').doc(uid).snapshots().map((snap) {
      final data = snap.data() ?? {};
      return UserData(
        name: data['name'] ?? '',
        profilePhotoUrl: data['profilePhoto'] ?? '',
        booksGoal: data['books'] ?? 0,
        booksRead: data['booksRead'] ?? 0,
      );
    });
  }

  @override
  Stream<List<Book>> getCurrentlyReadingBooks(String uid) {
    return _firestore
        .collection('reader')
        .doc(uid)
        .collection('currently reading')
        .snapshots()
        .asyncMap((snap) async {
      List<Book> books = [];
      for (var doc in snap.docs) {
        final bookId = doc['bookID'];
        final book = await _fetchBookFromGoogleAPI(bookId);
        books.add(book);
      }
      return books;
    });
  }

  Future<Book> _fetchBookFromGoogleAPI(String bookId) async {
    final url = 'https://www.googleapis.com/books/v1/volumes/$bookId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Book.fromGoogleBooksAPI(data);
    } else {
      throw Exception('Failed to load book data');
    }
  }

  @override
  Stream<List<Club>> getOwnedClubs(String uid) {
    return _firestore
        .collection('clubs')
        .where('ownerID', isEqualTo: uid)
        .snapshots()
        .asyncMap((snap) async {
      return Future.wait(snap.docs.map((doc) async {
        final membersSnap = await _firestore
            .collection('clubs')
            .doc(doc.id)
            .collection('members')
            .get();
        return Club.fromMap(doc.data() as Map<String, dynamic>, doc.id, membersSnap.size);
      }));
    });
  }

  @override
  Stream<List<Club>> getJoinedClubs(String uid) {
    return _firestore.collection('clubs').snapshots().asyncMap((snap) async {
      List<Club> result = [];
      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['ownerID'] != uid) {
          final member = await _firestore
              .collection('clubs')
              .doc(doc.id)
              .collection('members')
              .doc(uid)
              .get();
          if (member.exists) {
            final membersSnap = await _firestore
                .collection('clubs')
                .doc(doc.id)
                .collection('members')
                .get();
            result.add(Club.fromMap(data, doc.id, membersSnap.size));
          }
        }
      }
      return result;
    });
  }
}

