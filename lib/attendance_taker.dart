import 'package:flutter/material.dart';
import 'db_helper.dart'; // Import your DatabaseHelper

class AttendanceTakerPage extends StatefulWidget {
  final String date;
  final int courseId;

  const AttendanceTakerPage({super.key, required this.date, required this.courseId});

  @override
  _AttendanceTakerPageState createState() => _AttendanceTakerPageState();
}

class _AttendanceTakerPageState extends State<AttendanceTakerPage> {
  List<Map<String, dynamic>> _students = []; // List to hold students
  final Map<int, bool> _attendanceStatus = {}; // Track attendance status by student ID
  bool _isAllPresent = true; // Track if all students are present
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _loadStudentsAndAttendance(); // Load students and attendance when the page is initialized
  }

// Function to load students and their attendance status
  Future<void> _loadStudentsAndAttendance() async {
    try {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      // Load the students for the course
      List<Map<String, dynamic>> students = await DatabaseHelper.instance.getStudentsByCourse(widget.courseId);

      // Load the existing attendance records for the selected date
      List<Map<String, dynamic>> existingAttendance = await DatabaseHelper.instance.getAttendanceRecordsByDateAndCourse(widget.date, widget.courseId);

      if (mounted) {
        setState(() {
          _students = students;

          // Create a map of student IDs and their attendance status for quick lookup
          Map<int, bool> attendanceMap = {};

          // Populate the attendanceMap with fetched attendance records
          for (var record in existingAttendance) {
            try {
              // Ensure student_id and status are valid integers
              int? studentId = int.tryParse(record['student_id'].toString());
              int? status = int.tryParse(record['status'].toString());

              // Proceed only if studentId and status are valid
              if (studentId != null && status != null) {
                bool isPresent = status == 1; // 1 means present, 0 means absent
                attendanceMap[studentId] = isPresent;
              } else {
                print("Invalid data for record: $record"); // Log invalid records
              }
            } catch (e) {
              print("Error parsing attendance record: $e");
            }
          }

          // Track if all students are present based on the attendance records
          bool allPresent = true;

          for (var student in students) {
            int studentId = student['id'];

            // Check if there's a saved attendance record for this student
            if (attendanceMap.containsKey(studentId)) {
              bool isPresent = attendanceMap[studentId]!;
              _attendanceStatus[studentId] = isPresent;

              // If any student is absent, mark allPresent as false
              if (!isPresent) {
                allPresent = false;
              }
            } else {
              // Default to present if no attendance record exists for this student
              _attendanceStatus[studentId] = true;
            }
          }

          // Set _isAllPresent based on the attendance data loaded
          _isAllPresent = allPresent;

          _isLoading = false; // Data is loaded, hide the loading indicator
        });
      }
    } catch (e) {
      print("Error loading attendance data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }




  // Toggle attendance status for a single student
  void _toggleAttendance(int studentId, bool status) {
    setState(() {
      _attendanceStatus[studentId] = status;

      // If any student is absent, uncheck the "Mark All as Present" switch
      if (!status) {
        _isAllPresent = false;
      } else {
        // If all students are present, ensure _isAllPresent is true
        _isAllPresent = _attendanceStatus.values.every((value) => value == true);
      }
    });
  }

  // Mark all students as present or absent
  void _markAllPresent(bool isPresent) {
    setState(() {
      for (var student in _students) {
        _attendanceStatus[student['id']] = isPresent;
      }
      _isAllPresent = isPresent;
    });
  }

  // Save attendance to the database
  void _saveAttendance() async {
    for (var student in _students) {
      await DatabaseHelper.instance.insertOrUpdateAttendanceRecord({
        'date': widget.date,
        'student_id': student['id'],
        'course_id': widget.courseId,
        'status': _attendanceStatus[student['id']] == true ? 1 : 0, // 1 for present, 0 for absent
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance for ${widget.date}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAttendance, // Save attendance when check icon is pressed
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator while data is being fetched
          : Column(
        children: [
          ListTile(
            title: const Text('Mark all as Present'),
            trailing: Switch(
              value: _isAllPresent,
              onChanged: (value) {
                _markAllPresent(value); // Mark all students as present or absent
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return ListTile(
                  title: Text('${student['student_name']} (ID: ${student['student_id']})'),
                  trailing: Switch(
                    value: _attendanceStatus[student['id']] ?? true, // Show correct attendance status
                    onChanged: (value) {
                      _toggleAttendance(student['id'], value); // Toggle attendance for the student
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}