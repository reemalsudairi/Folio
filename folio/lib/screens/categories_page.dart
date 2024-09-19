import 'package:flutter/material.dart';
import 'package:folio/screens/book_list_page.dart';
import 'package:folio/services/google_books_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final GoogleBooksService _googleBooksService = GoogleBooksService();
  final TextEditingController _searchController = TextEditingController();

  final List<Color> pastelColors = [
    const Color(0xFFA9B6AC), // A greenish-gray
    const Color(0xFFf99a71), // A light coral
    const Color(0xFFfeb4c9), // A light pink
    const Color(0xFFe4e5a5), // A pale lime
    const Color(0xFF9ec4e8), // A soft blue
    const Color(0xFFFFE0B2), // A light orange
    const Color(0xFFB3C7E6), // A soft lavender-blue
    const Color(0xFFAFE1AF), // A light mint green
    const Color(0xFFFFD1DC), // A pale blush pink
    const Color.fromARGB(186, 184, 174, 133), // A soft pale yellow
    const Color(0xFFD5C1E5), // A light pastel purple
    const Color(0xFFFFC3A0), // A light peach
    const Color(0xFFCEEDFF), // A light sky blue
    const Color(0xFFFDE2E4), // A soft pinkish-red
    const Color(0xFFF6E1C3), // A warm beige
    const Color.fromARGB(255, 175, 206, 149), // A pale green
    const Color(0xFFF4BFBF), // A light pastel red
    const Color(0xFFF5DBA7), // A soft sand yellow
    const Color(0xFFF7D1CD), // A soft peach pink
    const Color(0xFFB5D8EB), // A soft light blue
  ];

  @override
  Widget build(BuildContext context) {
    final categories = _googleBooksService.getBookCategories();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      appBar: AppBar(
        title: const Text(
          'Explore',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Color(0xFF351F1F),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for a book',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                filled: true,
                fillColor: const Color.fromARGB(255, 255, 255, 255),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 20.0),
              ),
              onSubmitted: (String value) =>
                  _searchAndNavigate(context, value: value),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Categories",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Color(0xFF351F1F),
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Keeping 2 books per row
                childAspectRatio:
                    0.90, // Adjusting to make the book cards larger
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index]['category'];
                final icon = categories[index]['icon'];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookListPage(
                          searchTerm: category,
                          isCategory: true,
                        ),
                      ),
                    ).then((_) {
                      // Clear the search field when coming back to this page
                      _searchController.clear();
                    });
                  },
                  child: Card(
                    color: pastelColors[index % pastelColors.length],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 50,
                          color: const Color.fromARGB(223, 244, 238, 238),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _searchAndNavigate(BuildContext context, {String value = ''}) {
    final searchTerm =
        value.isEmpty ? _searchController.text.trim() : value.trim();

    if (searchTerm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a book name.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookListPage(
            searchTerm: searchTerm,
            isCategory: false,
          ),
        ),
      ).then((_) {
        // Clear the search field when coming back to this page
        _searchController.clear();
      });
    }
  }
}