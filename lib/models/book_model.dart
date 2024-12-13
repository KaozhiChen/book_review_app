class BookModel {
  final String bookId;
  final String title;
  final List<String> authors;
  final String status; // read, currently_reading, want_to_read
  final DateTime? timestamp;

  BookModel({
    required this.bookId,
    required this.title,
    required this.authors,
    required this.status,
    this.timestamp,
  });

  // cover to JSON and save to Firestore
  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'title': title,
      'authors': authors,
      'status': status,
      'timestamp': timestamp?.toUtc().toIso8601String(),
    };
  }

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      bookId: json['bookId'] as String,
      title: json['title'] as String,
      authors: List<String>.from(json['authors'] as List<dynamic>),
      status: json['status'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }
}
