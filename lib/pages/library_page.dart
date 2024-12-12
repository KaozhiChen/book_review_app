import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPage();
}

class _LibraryPage extends State<LibraryPage>
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

  Future<List<Map<String, dynamic>>> fetchBooks(String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final books = await FirebaseFirestore.instance
        .collection('user_books')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: status)
        .get();

    return books.docs.map((doc) => doc.data()).toList();
  }

  Future<void> removeBook(String bookId, String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('user_books')
          .where('userId', isEqualTo: user.uid)
          .where('bookId', isEqualTo: bookId)
          .where('status', isEqualTo: status)
          .get()
          .then((snapshot) {
        for (DocumentSnapshot ds in snapshot.docs) {
          ds.reference.delete();
        }
      });
      setState(() {});
    }
  }

  Widget buildBookList(List<Map<String, dynamic>> books, String status) {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final bookInfo = book['bookInfo'];
        final imageUrl = bookInfo['imageLinks'] != null
            ? bookInfo['imageLinks']['thumbnail']
            : 'https://via.placeholder.com/150';
        final bookId = book['bookId'];
        final rating = book['rating'] ?? 0;

        return Card(
          child: ListTile(
            leading: Image.network(imageUrl, fit: BoxFit.cover),
            title: Text(bookInfo['title'] ?? 'No Title'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bookInfo['authors'] != null
                    ? bookInfo['authors'].join(', ')
                    : 'No Author'),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    );
                  }),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => removeBook(bookId, status),
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
        title: const Text('Profile'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Read'),
            Tab(text: 'Currently Reading'),
            Tab(text: 'Want to Read'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchBooks('Read'),
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
          FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchBooks('Currently Reading'),
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
          FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchBooks('Want to Read'),
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
