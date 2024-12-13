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
