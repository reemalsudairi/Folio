class Book {
  final String id; // Unique ID for the book (from Google Books API)
  final String title; // Title of the book
  final String author; // Author(s) of the book
  final String thumbnailUrl; // URL for the book's thumbnail (image)
  final String description; // Description of the book (optional)
  final String publishedDate; // Published date of the book (optional)
  final int pageCount; // Number of pages in the book (optional)

  // Constructor to initialize the Book object
  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    this.description = '',
    this.publishedDate = '',
    this.pageCount = 0,
  });

  // Factory constructor to create a Book object from Google Books API data
  factory Book.fromGoogleBooksAPI(Map<String, dynamic> data) {
    var volumeInfo = data['volumeInfo'];
    return Book(
      id: data['id'] ?? 'Unknown ID',
      title: volumeInfo['title'] ?? 'No title available',
      author: (volumeInfo['authors'] != null && volumeInfo['authors'].isNotEmpty)
          ? volumeInfo['authors'].join(', ')
          : 'Unknown Author',
      thumbnailUrl: volumeInfo['imageLinks']?['thumbnail'] ??
          'https://via.placeholder.com/150', // Placeholder if thumbnail is missing
      description: volumeInfo['description'] ?? 'No description available',
      publishedDate: volumeInfo['publishedDate'] ?? 'Unknown date',
      pageCount: volumeInfo['pageCount'] ?? 0,
    );
  }
}

