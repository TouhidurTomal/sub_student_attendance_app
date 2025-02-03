import 'package:flutter/material.dart';
import 'package:csv/csv.dart'; // For CSV file creation
import 'package:open_file/open_file.dart'; // For opening files after creation
import 'package:path_provider/path_provider.dart'; // To get app directory for file storage
import 'package:file_picker/file_picker.dart'; // For picking file save location
import 'dart:io'; // For file IO
import 'db_helper.dart'; // Ensure database helper is configured
import 'course_detail_page.dart'; // Import CourseDetailPage

class CoursesPage extends StatefulWidget {
  final int facultyId; // Pass faculty ID to filter semesters

  const CoursesPage({super.key, required this.facultyId});

  @override
  _CoursesPageState createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  String? _selectedSemester; // Currently selected semester
  List<Map<String, dynamic>> _semesters = []; // List of semester maps (from DB)
  List<Map<String, dynamic>> _courses = []; // List of course maps (from DB)
  List<int> _selectedCourses = []; // Track selected courses by ID
  bool _isSelecting = false; // Track if selection mode is active

  @override
  void initState() {
    super.initState();
    _loadSemesters(); // Load semesters on page load
  }

  // Function to load semesters from the database
  void _loadSemesters() async {
    List<Map<String, dynamic>> semesters = await DatabaseHelper.instance.getSemestersByFaculty(widget.facultyId);
    setState(() {
      _semesters = semesters;
    });
  }

  // Function to load courses from the database based on the selected semester
  void _loadCourses(int semesterId) async {
    List<Map<String, dynamic>> courses = await DatabaseHelper.instance.getCoursesBySemester(semesterId);
    setState(() {
      _courses = courses;
    });
  }

  // Function to handle press and hold for selecting courses
  void _onCourseSelected(int courseId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedCourses.add(courseId);
      } else {
        _selectedCourses.remove(courseId);
      }
      _isSelecting = _selectedCourses.isNotEmpty; // Activate selection mode if any courses are selected
    });
  }

  // Exit selection mode
  void _exitSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedCourses.clear(); // Clear selected courses
    });
  }

  // Select or deselect all courses
  void _toggleSelectAll(bool isSelectAll) {
    setState(() {
      _selectedCourses = isSelectAll
          ? _courses.map((course) => course['id'] as int).toList() // Select all course IDs
          : [];
      _isSelecting = _selectedCourses.isNotEmpty;
    });
  }

  // Add a new semester
  void _addSemester() {
    final TextEditingController semesterController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Semester'),
          content: TextField(
            controller: semesterController,
            decoration: const InputDecoration(labelText: 'Semester Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                String semesterName = semesterController.text;
                if (semesterName.isNotEmpty) {
                  await DatabaseHelper.instance.insertSemester({
                    'semester_name': semesterName,
                    'faculty_id': widget.facultyId, // Link semester to the current faculty
                  });
                  _loadSemesters(); // Refresh semesters after adding
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Add a new course
  void _addCourse() {
    final TextEditingController courseController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Course'),
          content: TextField(
            controller: courseController,
            decoration: const InputDecoration(labelText: 'Course Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                String courseName = courseController.text;
                if (courseName.isNotEmpty && _selectedSemester != null) {
                  int semesterId = _semesters.firstWhere(
                          (semester) => semester['semester_name'] == _selectedSemester)['id'];
                  await DatabaseHelper.instance.insertCourse({
                    'course_name': courseName,
                    'semester_id': semesterId, // Link course to the selected semester
                  });
                  _loadCourses(semesterId); // Refresh courses after adding
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Edit semester
  void _editSemester(Map<String, dynamic> semester) {
    final TextEditingController semesterController =
    TextEditingController(text: semester['semester_name']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Semester'),
          content: TextField(
            controller: semesterController,
            decoration: const InputDecoration(labelText: 'Semester Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                String updatedName = semesterController.text;
                if (updatedName.isNotEmpty) {
                  await DatabaseHelper.instance.updateSemester({
                    'id': semester['id'],
                    'semester_name': updatedName,
                  });
                  _loadSemesters(); // Refresh semesters after editing
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Delete semester with confirmation
  void _deleteSemester(Map<String, dynamic> semester) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Semester'),
          content: const Text(
              'Are you sure you want to delete this semester? All related courses will be deleted.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await DatabaseHelper.instance.deleteSemester(semester['id']);
                _loadSemesters(); // Refresh semesters after deletion
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Edit course dialog
  void _editCourse(Map<String, dynamic> course) {
    final TextEditingController courseController =
    TextEditingController(text: course['course_name']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Course'),
          content: TextField(
            controller: courseController,
            decoration: const InputDecoration(labelText: 'Course Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                String updatedName = courseController.text;
                if (updatedName.isNotEmpty) {
                  await DatabaseHelper.instance.updateCourse({
                    'id': course['id'],
                    'course_name': updatedName,
                  });
                  _loadCourses(course['semester_id']); // Refresh courses
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Delete selected courses with confirmation
  void _confirmDeleteSelectedCourses() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Courses'),
          content: const Text(
              'Are you sure you want to delete the selected courses? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                for (var courseId in _selectedCourses) {
                  await DatabaseHelper.instance.deleteCourse(courseId);
                }
                _exitSelectionMode(); // Exit selection mode after deletion
                _loadCourses(_semesters.firstWhere(
                        (semester) => semester['semester_name'] == _selectedSemester)['id']);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Helper to show snackbar
  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Download course details, students, attendance, and CT/Assignment data to CSV
  Future<void> _downloadCsvFile(BuildContext context, int courseId, String courseName) async {
    List<List<dynamic>> rows = [];

    // Add course information
    rows.add(['Course Name: $courseName']);
    rows.add([]);

    // Fetch all attendance dates for the course
    List<Map<String, dynamic>> attendanceDates = await DatabaseHelper.instance.getAttendanceByCourse(courseId);
    List<String> headers = ['Student Name', 'Student ID'];

    // Add attendance date headers
    headers.addAll(attendanceDates.map((record) => record['attendance_date'] as String).toList());

    // Fetch all CT/Assignment data for the course
    List<Map<String, dynamic>> ctAssignments = await DatabaseHelper.instance.getCTAssignmentsByCourse(courseId);

    // Add CT/Assignment headers
    headers.addAll(ctAssignments.map((assignment) => assignment['assignment_name'] as String).toList());

    // Add headers to the CSV
    rows.add(headers);

    // Fetch students data
    List<Map<String, dynamic>> students = await DatabaseHelper.instance.getStudentsByCourse(courseId);

    // Add student data along with attendance and CT/assignment marks
    for (var student in students) {
      List<dynamic> row = [student['student_name'], student['student_id']];

      // Add attendance status for each date
      for (var attendanceDate in attendanceDates) {
        // Fetch attendance records for the current student and attendance date
        List<Map<String, dynamic>> attendanceRecords = await DatabaseHelper.instance.getAttendanceRecordsByDateAndCourse(
          attendanceDate['attendance_date'],
          courseId,
        );

        var studentAttendance = attendanceRecords.firstWhere(
              (att) => att['student_id'] == student['student_id'],  // Ensure correct student ID check
          orElse: () => {'status': 0}, // Default to Absent if no record is found
        );

        // Add "Present" or "Absent" based on the status
        row.add(studentAttendance['status'] == 1 ? 'Present' : 'Absent');
      }

      // Add CT/Assignment marks for each assignment
      for (var assignment in ctAssignments) {
        // Fetch marks for each assignment for the current student
        List<Map<String, dynamic>> ctRecords = await DatabaseHelper.instance.getStudentMarksByAssignment(assignment['id']);

        // Check if the current student has marks for this assignment
        var studentCTRecord = ctRecords.firstWhere(
              (ct) => ct['student_id'] == student['student_id'],  // Ensure correct student ID check
          orElse: () => {'obtained_marks': 0}, // Default to 0 if no record is found
        );

        // Add the marks or 0 if no marks are found
        row.add(studentCTRecord['obtained_marks'] ?? 0);  // Handle possible null values

        // Debugging: Log marks for each student and assignment
        print('Student ID: ${student['student_id']}, Assignment: ${assignment['assignment_name']}, Marks: ${studentCTRecord['obtained_marks']}');
      }

      rows.add(row);
    }

    // Convert rows to CSV format
    String csvData = const ListToCsvConverter().convert(rows);

    // Save the CSV file in a selected directory
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      String path = '$selectedDirectory/course_data_${courseName}.csv';
      File file = File(path)
        ..createSync(recursive: true)
        ..writeAsStringSync(csvData);

      // Notify user and offer to open the file
      _showSnackBar(context, 'CSV file saved at $path');
      await OpenFile.open(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isSelecting
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode, // Exit selection mode
        )
            : null,
        title: const Text('Courses'),
        actions: _isSelecting
            ? [
          Checkbox(
            value: _selectedCourses.length == _courses.length && _courses.isNotEmpty,
            onChanged: (value) => _toggleSelectAll(value ?? false),
          ),
        ]
            : [],
      ),
      body: Column(
        children: [
          // Top icon (courses.jpg)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Image.asset('images/courses.jpg', height: 100), // Replace with actual path to courses.jpg
            ),
          ),

          // Semester dropdown and add button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                hint: const Text('Select Semester'),
                value: _selectedSemester,
                items: _semesters.map((semester) {
                  return DropdownMenuItem<String>(
                    value: semester['semester_name'],
                    child: Row(
                      children: [
                        Text(semester['semester_name']),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _editSemester(semester); // Edit semester
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _deleteSemester(semester); // Delete semester with warning
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSemester = newValue;
                    if (_selectedSemester != null) {
                      int semesterId = _semesters
                          .firstWhere((semester) => semester['semester_name'] == _selectedSemester)['id'];
                      _loadCourses(semesterId); // Load courses when a semester is selected
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addSemester, // Add new semester
              ),
            ],
          ),

          // Display the courses under the selected semester
          Expanded(
            child: _selectedSemester == null
                ? const Center(child: Text('Please select a semester.'))
                : _courses.isEmpty
                ? const Center(child: Text('No courses available.'))
                : ListView.builder(
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                final isSelected = _selectedCourses.contains(course['id']);
                return ListTile(
                  leading: _isSelecting
                      ? Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      _onCourseSelected(course['id'], value ?? false);
                    },
                  )
                      : null,
                  title: Text(course['course_name']),
                  selected: isSelected,
                  selectedTileColor: Colors.teal.withOpacity(0.3),
                  onLongPress: () {
                    _onCourseSelected(course['id'], !isSelected); // Enable selection mode
                  },
                  onTap: () {
                    if (_isSelecting) {
                      _onCourseSelected(course['id'], !isSelected);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseDetailPage(
                            courseName: course['course_name'], // Pass courseName
                            courseId: course['id'], // Pass courseId
                          ),
                        ),
                      ); // Navigate to the CourseDetailPage
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !_isSelecting
          ? FloatingActionButton(
        onPressed: _addCourse, // Add new course
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      )
          : null, // Hide when in selection mode
      bottomNavigationBar: _isSelecting ? _buildActionButtons() : null,
    );
  }

  // Bottom action buttons widget
  Widget _buildActionButtons() {
    bool isMultiple = _selectedCourses.length > 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.grey, spreadRadius: 2)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            onPressed: isMultiple
                ? null
                : () => _editCourse(
                _courses.firstWhere((course) => course['id'] == _selectedCourses.first)),
            style: ElevatedButton.styleFrom(
              foregroundColor: isMultiple ? Colors.grey : Colors.white,
              backgroundColor: isMultiple ? Colors.grey : Colors.blue,
            ),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: _confirmDeleteSelectedCourses,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          ElevatedButton(
            onPressed: _selectedCourses.length == 1
                ? () {
              var selectedCourse = _courses.firstWhere((course) => course['id'] == _selectedCourses.first);
              _downloadCsvFile(context, selectedCourse['id'], selectedCourse['course_name']); // CSV download
            }
                : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Download'),
          ),

        ],
      ),
    );
  }
}