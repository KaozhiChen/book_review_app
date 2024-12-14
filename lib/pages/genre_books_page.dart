import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:book_review_app/pages/book_details_page.dart';

class GenreBooksPage extends StatelessWidget {
  final String genre;

  const GenreBooksPage({super.key, required this.genre});

  Future<List<Map<String, dynamic>>> fetchBooksByGenre(String genre) async {
    final response = await http.get(
      Uri.parse('https://www.googleapis.com/books/v1/volumes?q=subject:$genre&maxResults=20'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['items'] as List).map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(genre),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchBooksByGenre(genre),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading books'));
          }
          final books = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final volumeInfo = book['volumeInfo'];
              final imageUrl = volumeInfo['imageLinks'] != null
                  ? volumeInfo['imageLinks']['thumbnail']
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
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ListTile(
                    leading: Image.network(imageUrl, fit: BoxFit.cover),
                    title: Text(volumeInfo['title'] ?? 'No Title'),
                    subtitle: Text(volumeInfo['authors'] != null
                        ? volumeInfo['authors'].join(', ')
                        : 'No Author'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
