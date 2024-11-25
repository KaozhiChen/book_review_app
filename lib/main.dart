import 'package:book_review_app/pages/splash_page.dart';
import 'package:book_review_app/theme/colors.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Review App',
      theme: ThemeData(
        fontFamily: 'OpenSans',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
      ),
      home: const SplashPage(),
    );
  }
}
