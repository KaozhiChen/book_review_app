import 'package:book_review_app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<dynamic> books = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  bool isFetchingMore = false;
  int currentPage = 0; // the index of current page
  final int pageSize = 5; // the number of loading books
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchRecommendedBooks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // get user preferances and reviews
  Future<Map<String, List<String>>> fetchUserPreferencesAndReviews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {"preferences": [], "favoriteGenres": []};
    }

    // get user preferences
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    List<String> preferences = [];
    if (userDoc.exists && userDoc.data() != null) {
      preferences = List<String>.from(userDoc.data()!['preferences'] ?? []);
    }

    // get high rating genres
    final reviewsQuery = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .where('rating', isGreaterThanOrEqualTo: 4)
        .get();
    final favoriteGenres = reviewsQuery.docs
        .expand((doc) {
          final genre = doc.data()['genre'] as String;
          return genre.split('/').map((g) => g.trim());
        })
        .toSet()
        .toList();

    return {"preferences": preferences, "favoriteGenres": favoriteGenres};
  }

  // get recommended books
  Future<void> fetchRecommendedBooks({bool loadMore = false}) async {
    if (isLoading || isFetchingMore) return;

    if (loadMore) {
      setState(() {
        isFetchingMore = true;
      });
    } else {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // get genres according to user's preferences and rating
      final userData = await fetchUserPreferencesAndReviews();
      final preferences = userData['preferences'];
      final favoriteGenres = userData['favoriteGenres'];

      const baseUrl = "https://www.googleapis.com/books/v1/volumes?q=subject:";

      List<dynamic> fetchedBooks = [];

      // priorotize recommended books base on high ratings
      if (favoriteGenres!.isNotEmpty) {
        for (String genre in favoriteGenres) {
          final response = await http.get(Uri.parse(
              "$baseUrl$genre&startIndex=${currentPage * pageSize}&maxResults=$pageSize"));
          print("Fetching books for genre: $genre, Response: ${response.body}");
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            fetchedBooks.addAll(data['items'] ?? []);
          }
        }
      }

      // base on preferences secondly
      if (preferences!.isNotEmpty) {
        for (String preference in preferences) {
          final response = await http.get(Uri.parse(
              "$baseUrl$preference&startIndex=${currentPage * pageSize}&maxResults=$pageSize"));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            fetchedBooks.addAll(data['items'] ?? []);
          }
        }
      }

      setState(() {
        if (loadMore) {
          books.addAll(fetchedBooks);
        } else {
          books = fetchedBooks;
        }
        currentPage++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
    }
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

  void _onScroll() {
    if (_scrollController.position.extentAfter < 100 && !isFetchingMore) {
      fetchRecommendedBooks(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (isLoading) {
      // loading animation
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Book Review App'),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: [
              // search bar
              const SizedBox(
                height: 16,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for books...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14.0, horizontal: 20.0),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        searchBooks(searchController.text);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Think you might like...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // book list
              Expanded(
                child: Stack(
                  children: [
                    GridView.builder(
                      controller: _scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78,
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
                                builder: (context) =>
                                    BookDetailsPage(book: book),
                              ),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    height: 140,
                                    width: double.infinity,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bookInfo['title'] ?? 'No Title',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        bookInfo['authors'] != null
                                            ? bookInfo['authors'].join(', ')
                                            : 'No Author',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (isFetchingMore)
                      const Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
              // loading animation
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ));
  }
}
