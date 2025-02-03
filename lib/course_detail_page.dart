import 'package:flutter/material.dart';
import 'student_page.dart'; // Import the StudentPage
import 'attendance_page.dart'; // Import the AttendancePage
import 'ct_assignment_page.dart'; // Import the CTAssignmentPage

class CourseDetailPage extends StatelessWidget {
  final String courseName; // To dynamically set the course name
  final int courseId; // Add a courseId parameter to track the course

  const CourseDetailPage({super.key, required this.courseName, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(courseName), // Set the course name as the title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Students option
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Students'),
              onTap: () {
                // Navigate to the Students page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentPage(courseId: courseId), // Pass the courseId to StudentPage
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // Attendance option
            ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('Attendance'),
              onTap: () {
                // Navigate to the Attendance page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttendancePage(
                      courseId: courseId,
                      courseName: courseName, // Pass courseId and courseName to AttendancePage
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // CT/Assignment option
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('CT/Assignment'),
              onTap: () {
                // Navigate to the CT/Assignment page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CTAssignmentPage(
                      courseId: courseId,
                      courseName: courseName, // Pass courseId and courseName to CTAssignmentPage
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
