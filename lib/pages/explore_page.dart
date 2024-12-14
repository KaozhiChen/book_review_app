import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_review_app/pages/book_details_page.dart';
import 'package:book_review_app/pages/genre_books_page.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  static const List<Map<String, String>> genres = [
    {'name': 'Fiction', 'image': 'assets/images/Fiction.jpg'},
    {'name': 'Fantasy', 'image': 'assets/images/Fantasy.jpg'},
    {'name': 'Science Fiction', 'image': 'assets/images/Science Fiction.jpg'},
    {'name': 'Mystery', 'image': 'assets/images/Mystery.jpg'},
    {'name': 'Romance', 'image': 'assets/images/Romance.jpeg'},
    {'name': 'Horror', 'image': 'assets/images/Horror.jpeg'},
    {'name': 'Biography', 'image': 'assets/images/Biography.jpg'},
    {'name': 'History', 'image': 'assets/images/History.jpg'},
    {'name': 'Poetry', 'image': 'assets/images/Poetry.jpg'},
    {'name': 'Adventure', 'image': 'assets/images/Adventure.jpg'},
    {'name': 'Children', 'image': 'assets/images/Children.jpeg'},
    {'name': 'Travel', 'image': 'assets/images/Travel.jpg'},
    {'name': 'Cooking', 'image': 'assets/images/Cooking.jpeg'},
    {'name': 'Religion', 'image': 'assets/images/Religion.jpg'},
    {'name': 'Art', 'image': 'assets/images/Art.jpg'},
    {'name': 'Health', 'image': 'assets/images/Health.jpeg'},
    {'name': 'Business', 'image': 'assets/images/Business.jpeg'},
    {'name': 'Technology', 'image': 'assets/images/Technology.jpg'},
    {'name': 'Education', 'image': 'assets/images/Education.jpeg'},
    {'name': 'Drama', 'image': 'assets/images/Drama.jpeg'},
    {'name': 'Philosophy', 'image': 'assets/images/Philosophy.jpeg'},
    {'name': 'Science', 'image': 'assets/images/Science.jpeg'},
    {'name': 'Sports', 'image': 'assets/images/Sports.jpg'},
    {'name': 'Politics', 'image': 'assets/images/Politics.jpg'},
    {'name': 'Economics', 'image': 'assets/images/Economics.jpg'},
  ];

  Future<void> scanBarcode(BuildContext context) async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode) {
        String isbn = result.rawContent;
        fetchBookDetails(context, isbn);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan barcode: $e')),
      );
    }
  }

  Future<void> fetchBookDetails(BuildContext context, String isbn) async {
  final response = await http.get(
    Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn'),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['totalItems'] > 0) {
      final book = data['items'][0];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookDetailsPage(book: book),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No book found with this ISBN')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to fetch book details')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Genres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => scanBarcode(context),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: genres.length,
        itemBuilder: (context, index) {
          final genre = genres[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GenreBooksPage(genre: genre['name']!),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(genre['image']!),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    genre['name']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
