import 'package:flutter/material.dart';
import 'db_helper.dart';  // Your database helper import

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeDatabase();  // Initialize the database in the background
  }

  // Initialize the database
  Future<void> _initializeDatabase() async {
    await DatabaseHelper.instance.database;  // This will initialize the database
    _navigateToHome();  // Navigate to the home screen after initialization
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal, // Match the background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The logo image can be added here, if it's a local asset.
            Image.asset('assets/logo.png', height: 150), // Update with your actual logo path
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
              onPressed: _navigateToHome, // Navigate to home manually if needed
              child: const Text('Get Started'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.teal, backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
