import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'faculty_screen.dart';  // Import FacultyScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      debugShowCheckedModeBanner: false,  // This line removes the debug banner
      home: const HomeScreen(),  // Start with HomeScreen
      routes: {
        '/faculty': (context) => const FacultyScreen(),  // Define the named route for FacultyScreen
      },
    );
  }
}
