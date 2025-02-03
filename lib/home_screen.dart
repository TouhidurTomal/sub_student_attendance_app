import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal, // Match the background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or image that you want at the center
            Image.asset('images/Logo.png', height: 150), // Your logo path
            const SizedBox(height: 20),
            const Text(
              'SUB Attendance App',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate using named route to FacultyScreen
                Navigator.pushNamed(context, '/faculty');
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.teal, backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
