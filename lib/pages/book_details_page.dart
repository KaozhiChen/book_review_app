import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookDetailsPage extends StatefulWidget {
  final dynamic book;

  const BookDetailsPage({super.key, required this.book});

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 0;
  String _readingStatus = 'Read';

  Future<double> getAverageRating(String bookId) async {
    final ratings = await FirebaseFirestore.instance
        .collection('ratings')
        .where('bookId', isEqualTo: bookId)
        .get();

    if (ratings.docs.isEmpty) return 0.0;

    double totalRating = 0.0;
    for (var doc in ratings.docs) {
      totalRating += doc['rating'];
    }

    return totalRating / ratings.docs.length;
  }

  Future<void> submitReview(String bookId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to submit a review")),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a review and rating")),
      );
      return;
    }

    try {
      // get username
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final username = userDoc.data()?['username'] ?? 'Anonymous';

      // submit review
      await FirebaseFirestore.instance.collection('reviews').add({
        'bookId': bookId,
        'userId': user.uid,
        'review': _reviewController.text.trim(),
        'rating': _rating,
        'timestamp': FieldValue.serverTimestamp(),
        'username': username,
      });

      setState(() {
        _reviewController.clear();
        _rating = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit review: $e")),
      );
    }

    // if (user != null) {
    //   final bookDoc = await FirebaseFirestore.instance
    //       .collection('books')
    //       .doc(bookId)
    //       .get();
    //   if (bookDoc.exists) {
    //     final book = bookDoc.data();
    //     final genre = book!['genre'];
    //     final authors =
    //         book['authors'] != null ? List<String>.from(book['authors']) : [];
    //     final publicationDate = book['publishedDate'];

    //     await FirebaseFirestore.instance.collection('reviews').add({
    //       'bookId': bookId,
    //       'userId': user.uid,
    //       'review': _reviewController.text,
    //       'rating': _rating,
    //       'genre': genre,
    //       'authors': authors,
    //       'publishedDate': publicationDate,
    //       'timestamp': FieldValue.serverTimestamp(),
    //     });

    //     await FirebaseFirestore.instance.collection('ratings').add({
    //       'bookId': bookId,
    //       'userId': user.uid,
    //       'rating': _rating,
    //       'genre': genre,
    //       'authors': authors,
    //       'publishedDate': publicationDate,
    //     });

    //     setState(() {
    //       _readingStatus = 'Read';
    //       _rating = 0;
    //     });
    //   }
    // }
  }

  Future<void> submitReadingStatus(String bookId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('user_books')
          .doc(bookId)
          .set({
        'userId': user.uid,
        'bookId': bookId,
        'status': _readingStatus,
        'bookInfo': widget.book['volumeInfo'],
        'rating': _rating,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookInfo = widget.book['volumeInfo'];
    final imageUrl = bookInfo['imageLinks'] != null
        ? bookInfo['imageLinks']['thumbnail']
        : 'https://via.placeholder.com/150';
    final bookId = widget.book['id'];

    return Scaffold(
      appBar: AppBar(
        title: Text(bookInfo['title'] ?? 'Book Details'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
                Text(
                  bookInfo['title'] ?? 'No Title',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  bookInfo['authors'] != null
                      ? bookInfo['authors'].join(', ')
                      : 'No Author',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                FutureBuilder<double>(
                  future: getAverageRating(bookId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return const Text('Error loading rating');
                    }
                    return Text(
                      'Average Rating: ${snapshot.data?.toStringAsFixed(1) ?? 'N/A'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    );
                  },
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: _readingStatus,
                  items: <String>['Read', 'Currently Reading', 'Want to Read']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _readingStatus = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => submitReadingStatus(bookId),
                      child: const Text('Submit'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _readingStatus = 'Read';
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  bookInfo['description'] ?? 'No Description',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Number of Pages: ${bookInfo['pageCount'] ?? 'N/A'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _reviewController,
                  decoration: const InputDecoration(
                    labelText: 'Write a review',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Rating: ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ...List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                        ),
                        color: Colors.amber,
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                      );
                    }),
                  ],
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () => submitReview(bookId),
                    child: const Text('Submit Review'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reviews:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('bookId', isEqualTo: bookId)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("Failed to load reviews"),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No reviews yet."),
                      );
                    }

                    // get review list
                    final reviews = snapshot.data!.docs;
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      separatorBuilder: (context, index) => const Divider(
                        thickness: 1.0,
                        height: 20,
                      ),
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        final timestamp = review['timestamp'] != null
                            ? (review['timestamp'] as Timestamp).toDate()
                            : null;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // avatar and username
                              Row(
                                children: [
                                  CircleAvatar(
                                    child: Text(
                                      review['username'][0].toUpperCase(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    review['username'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // ranking and time
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // ranking
                                  Row(
                                    children: List.generate(5, (starIndex) {
                                      return Icon(
                                        starIndex < review['rating']
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 20,
                                      );
                                    }),
                                  ),
                                  // time
                                  if (timestamp != null)
                                    Text(
                                      "${timestamp.day}-${timestamp.month}-${timestamp.year}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // review content
                              Text(
                                review['review'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
