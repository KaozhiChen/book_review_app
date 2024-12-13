import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id; // review ID
  final String bookId; // book ID
  final String userId; // user ID
  final String review; // user review
  final int rating; // user rating
  final DateTime timestamp; // review time
  final String username; // username

  ReviewModel({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.review,
    required this.rating,
    required this.timestamp,
    required this.username,
  });

  // create ReviewModel from firebase
  factory ReviewModel.fromJson(Map<String, dynamic> json, String id) {
    return ReviewModel(
      id: id,
      bookId: json['bookId'],
      userId: json['userId'],
      review: json['review'],
      rating: json['rating'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      username: json['username'] ?? 'Anonymous',
    );
  }

  /// recover to JSON to write in Firebase
  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'userId': userId,
      'review': review,
      'rating': rating,
      'timestamp': Timestamp.fromDate(timestamp),
      'username': username,
    };
  }

  // add review to Firestore
  static Future<void> addReview(ReviewModel review) async {
    await FirebaseFirestore.instance.collection('reviews').add(review.toJson());
  }

  // get reviews
  static Future<List<ReviewModel>> getReviewsByBook(String bookId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('bookId', isEqualTo: bookId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return ReviewModel.fromJson(doc.data(), doc.id);
    }).toList();
  }

  // delete review
  static Future<void> deleteReview(String reviewId) async {
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .delete();
  }

  // update review
  static Future<void> updateReview(
      String reviewId, String newReview, int newRating) async {
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .update({
      'review': newReview,
      'rating': newRating,
      'timestamp': Timestamp.now(), // update time
    });
  }
}
