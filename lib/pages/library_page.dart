import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book_model.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Stream to fetch books by status
  Stream<List<BookModel>> fetchBooksStream(String status) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('user_books')
        .doc(user.uid)
        .collection('books')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookModel.fromJson(doc.data()))
            .toList());
  }

  // Remove book from Firestore
  Future<void> removeBook(String bookId, String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('user_books')
          .doc(user.uid)
          .collection('books')
          .doc(bookId);

      await docRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Book removed successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove book: $e")),
      );
    }
  }

  // Build list of books
  Widget buildBookList(List<BookModel> books, String status) {
    if (books.isEmpty) {
      return Center(
        child: Text(
          'No books in $status.',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: ListTile(
            leading: Image.network(
              book.imageUrl,
              fit: BoxFit.cover,
              width: 50,
              height: 75,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/default_book.png',
                  fit: BoxFit.cover,
                  width: 50,
                  height: 75,
                );
              },
            ),
            title: Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              book.authors.join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => removeBook(book.bookId, status),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Read'),
            Tab(text: 'Reading'),
            Tab(text: 'Want to Read'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder<List<BookModel>>(
            stream: fetchBooksStream('read'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading books'));
              }
              return buildBookList(snapshot.data ?? [], 'Read');
            },
          ),
          StreamBuilder<List<BookModel>>(
            stream: fetchBooksStream('currently_reading'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading books'));
              }
              return buildBookList(snapshot.data ?? [], 'Currently Reading');
            },
          ),
          StreamBuilder<List<BookModel>>(
            stream: fetchBooksStream('want_to_read'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading books'));
              }
              return buildBookList(snapshot.data ?? [], 'Want to Read');
            },
          ),
        ],
      ),
    );
  }
}
