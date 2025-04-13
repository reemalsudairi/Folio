import 'package:folio/screens/Profile/book.dart';
import 'Profile/clubs_page.dart';
 

abstract class HomeDataService {
  Stream<UserData> getUserData(String uid);
  Stream<List<Book>> getCurrentlyReadingBooks(String uid);
  Stream<List<Club>> getOwnedClubs(String uid);
  Stream<List<Club>> getJoinedClubs(String uid);
}

class UserData {
  final String name;
  final String profilePhotoUrl;
  final int booksGoal;
  final int booksRead;

  UserData({
    required this.name,
    required this.profilePhotoUrl,
    required this.booksGoal,
    required this.booksRead,
  });
}

