import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/colors.dart';
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
  List<dynamic> originalBooks = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  bool isFetchingMore = false;
  bool isSearching = false;
  int currentPage = 0;
  final int pageSize = 5;
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

  // get preferences and ratings
  Future<Map<String, List<String>>> fetchUserPreferencesAndReviews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {"preferences": [], "favoriteGenres": []};
    }

    try {
      // Fetch user preferences
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      List<String> preferences = [];
      if (userDoc.exists && userDoc.data() != null) {
        preferences = List<String>.from(userDoc.data()!['preferences'] ?? []);
      }

      // Fetch user high-rated books and dynamically get genres using bookId
      final reviewsQuery = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .where('rating', isGreaterThanOrEqualTo: 4)
          .get();

      Set<String> favoriteGenres = {};

      for (var review in reviewsQuery.docs) {
        final bookId = review.data()['bookId'];
        if (bookId != null) {
          final genres = await fetchGenreFromGoogleBooks(bookId);
          if (genres.isNotEmpty) {
            favoriteGenres.addAll(genres);
          }
        }
      }

      return {
        "preferences": preferences,
        "favoriteGenres": favoriteGenres.toList(),
      };
    } catch (e) {
      return {"preferences": [], "favoriteGenres": []};
    }
  }

  Future<List<String>> fetchGenreFromGoogleBooks(String bookId) async {
    const baseUrl = "https://www.googleapis.com/books/v1/volumes";
    try {
      final response = await http.get(Uri.parse("$baseUrl/$bookId"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categories =
            data['volumeInfo']?['categories'] as List<dynamic>? ?? [];
        return categories.map((category) => category.toString()).toList();
      }
    } catch (e) {
      print('Error fetching genre for bookId $bookId: $e');
    }
    return [];
  }

  // get recommand books
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
      final userData = await fetchUserPreferencesAndReviews();
      final preferences = userData['preferences'];
      final favoriteGenres = userData['favoriteGenres'];

      const baseUrl = "https://www.googleapis.com/books/v1/volumes?q=subject:";
      List<dynamic> fetchedBooks = [];

      if (favoriteGenres!.isNotEmpty) {
        final simplifiedGenres = favoriteGenres
            .map((genre) => genre.split('/').first.trim())
            .toSet();

        for (String genre in simplifiedGenres) {
          final response = await http.get(Uri.parse(
              "$baseUrl$genre&startIndex=${currentPage * pageSize}&maxResults=$pageSize"));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            fetchedBooks.addAll(data['items'] ?? []);
          } else {
            print('Failed to fetch books for genre: $genre');
          }
        }
      }

      // preferences
      if (preferences!.isNotEmpty) {
        for (String preference in preferences) {
          final response = await http.get(Uri.parse(
              "$baseUrl$preference&startIndex=${currentPage * pageSize}&maxResults=$pageSize"));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            print(
                'Books fetched for $preference: ${data['items']?.length ?? 0}');
            fetchedBooks.addAll(data['items'] ?? []);
          } else {
            print('Failed to fetch books for preference: $preference');
          }
        }
      }

      // if not references
      if (fetchedBooks.isEmpty) {
        final response = await http.get(Uri.parse(
            "$baseUrl+Fiction&startIndex=${currentPage * pageSize}&maxResults=$pageSize"));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          fetchedBooks.addAll(data['items'] ?? []);
        }
      }

      setState(() {
        if (loadMore) {
          books.addAll(fetchedBooks);
        } else {
          books = fetchedBooks;
          if (originalBooks.isEmpty) {
            originalBooks = List.from(books);
          }
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

  // search books
  Future<void> searchBooks(String query) async {
    FocusScope.of(context).unfocus();
    setState(() {
      isSearching = true;
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse(
          "https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=20"),
    );

    if (response.statusCode == 200) {
      setState(() {
        books = json.decode(response.body)['items'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Failed to load books')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  void _onScroll() {
    if (!isSearching &&
        _scrollController.position.extentAfter < 100 &&
        !isFetchingMore) {
      fetchRecommendedBooks(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Review App'),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
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
                    suffixIcon: isSearching
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                isSearching = false;
                                searchController.clear();
                                books = List.from(originalBooks);
                              });
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              searchBooks(searchController.text);
                            },
                          ),
                  ),
                  onSubmitted: (query) => searchBooks(query),
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
                    if (books.isEmpty && isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else if (books.isNotEmpty)
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
            ],
          ),
        ),
      ),
    );
  }
}
