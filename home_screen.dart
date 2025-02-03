import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'faculty_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to your Faculty Management, Course Management, or any other feature
            Navigator.push(context, MaterialPageRoute(builder: (context) => FacultyScreen()));
          },
          child: const Text('Manage Faculties'),
        ),
      ),
    );
  }
}
