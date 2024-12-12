import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> books = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecommendedBooks();
  }

  // get user preferances
  Future<List<String>> fetchUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return [];
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      final preferences = List<String>.from(doc.data()!['preferences'] ?? []);

      return preferences;
    }

    // return [] if no preferance
    return [];
  }

  Future<void> fetchRecommendedBooks() async {
    setState(() {
      isLoading = true;
    });

    final preferences = await fetchUserPreferences();

    List<dynamic> recommendedBooks = [];
    const baseUrl = "https://www.googleapis.com/books/v1/volumes?q=subject:";

    try {
      if (preferences.isNotEmpty) {
        // fetch books according to preferences
        for (String preference in preferences) {
          final response =
              await http.get(Uri.parse("$baseUrl$preference&maxResults=20"));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            recommendedBooks.addAll(data['items'] ?? []);
          }
        }
      } else {
        final response =
            await http.get(Uri.parse("$baseUrl+Fiction&maxResults=20"));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          recommendedBooks.addAll(data['items'] ?? []);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() {
      books = recommendedBooks;
      isLoading = false;
    });
  }

  Future<void> searchBooks(String query) async {
    final response = await http.get(
      Uri.parse(
          "https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=20"),
    );

    if (response.statusCode == 200) {
      setState(() {
        books = json.decode(response.body)['items'];
      });
    } else {
      throw Exception('Failed to load books');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Review App'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for books...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    searchBooks(searchController.text);
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.6,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                final bookInfo = book['volumeInfo'];
                final imageUrl = bookInfo['imageLinks'] != null
                    ? bookInfo['imageLinks']['thumbnail']
                    : 'https://via.placeholder.com/150';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailsPage(book: book),
                      ),
                    );
                  },
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(imageUrl, fit: BoxFit.cover),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            bookInfo['title'] ?? 'No Title',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            bookInfo['authors'] != null
                                ? bookInfo['authors'].join(', ')
                                : 'No Author',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
}

class BookDetailsPage extends StatefulWidget {
  final dynamic book;

  const BookDetailsPage({Key? key, required this.book}) : super(key: key);

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
    if (user != null) {
      final bookDoc = await FirebaseFirestore.instance
          .collection('books')
          .doc(bookId)
          .get();
      if (bookDoc.exists) {
        final book = bookDoc.data();
        final genre = book!['genre'];
        final authors =
            book['authors'] != null ? List<String>.from(book['authors']) : [];
        final publicationDate = book['publishedDate'];

        await FirebaseFirestore.instance.collection('reviews').add({
          'bookId': bookId,
          'userId': user.uid,
          'review': _reviewController.text,
          'rating': _rating,
          'genre': genre,
          'authors': authors,
          'publishedDate': publicationDate,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update the rating collection
        await FirebaseFirestore.instance.collection('ratings').add({
          'bookId': bookId,
          'userId': user.uid,
          'rating': _rating,
          'genre': genre,
          'authors': authors,
          'publishedDate': publicationDate,
        });

        // Mark the book as read
        setState(() {
          _readingStatus = 'Read';
        });

        _reviewController.clear();
        setState(() {
          _rating = 0;
        });
      }
    }
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
      body: Padding(
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
              const SizedBox(height: 16),
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
                children: List.generate(5, (index) {
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
              ),
              ElevatedButton(
                onPressed: () => submitReview(bookId),
                child: const Text('Submit Review'),
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
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final reviews = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return ListTile(
                        title: Text(review['review']),
                        subtitle: Text('Rating: ${review['rating']}'),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
