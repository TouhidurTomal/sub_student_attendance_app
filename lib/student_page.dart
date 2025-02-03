import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart'; // For parsing CSV
import 'package:excel/excel.dart'; // For parsing Excel
import 'dart:io'; // For file IO
import 'package:file_picker/file_picker.dart'; // For file picking
import 'db_helper.dart'; // Import your database helper
import 'student.dart';

class StudentPage extends StatefulWidget {
  final int courseId;

  const StudentPage({super.key, required this.courseId});

  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  List<Student> _students = []; // Change the list to hold Student objects
  List<int> _selectedStudents = []; // Track selected students by ID
  bool _isSelecting = false; // Track if selection mode is active

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  // Function to load students for the course
  void _loadStudents() async {
    List<Map<String, dynamic>> studentsData =
    await DatabaseHelper.instance.getStudentsByCourse(widget.courseId);
    List<Student> students = studentsData.map((data) => Student.fromMap(data)).toList();

    setState(() {
      _students = students;
    });
  }

  // Function to add a new student manually
  void _addStudent() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController idController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Student'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Student Name'),
              ),
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
            ],
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
                String studentName = nameController.text;
                String studentId = idController.text;
                if (studentName.isNotEmpty && studentId.isNotEmpty) {
                  // Create the new student without explicitly setting the ID
                  Student newStudent = Student(
                    studentName: studentName,
                    studentId: studentId,
                    courseId: widget.courseId,
                  );

                  // Insert the student into the database
                  int result = await DatabaseHelper.instance.insertStudent(newStudent);

                  // Reload students to refresh the list
                  _loadStudents();
                }
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Function to import students from CSV/Excel using file picker
  void _importFromCSVExcel() async {
    // Open file picker to select CSV or Excel file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xls', 'xlsx'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String extension = result.files.single.extension!.toLowerCase();

      if (extension == 'csv') {
        final input = file.openRead();
        final fields = await input
            .transform(utf8.decoder)
            .transform(const CsvToListConverter())
            .toList();
        _parseAndAddStudentsFromCSV(fields);
      } else if (extension == 'xls' || extension == 'xlsx') {
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        _parseAndAddStudentsFromExcel(excel);
      }
    }
  }

  void _parseAndAddStudentsFromCSV(List<List<dynamic>> fields) async {
    List<Student> importedStudents = [];

    for (var row in fields) {
      if (row.length >= 2) {
        String studentName = row[0]?.toString().trim() ?? '';
        String studentId = row[1]?.toString().trim() ?? '';

        if (studentName.isNotEmpty && studentId.isNotEmpty) {
          importedStudents.add(Student(studentName: studentName, studentId: studentId, courseId: widget.courseId));
        }
      }
    }

    for (var student in importedStudents) {
      await DatabaseHelper.instance.insertStudent(student);
    }

    _loadStudents(); // Refresh the student list
  }

  void _parseAndAddStudentsFromExcel(Excel excel) async {
    List<Student> importedStudents = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null) continue;

      for (var row in sheet.rows) {
        if (row.length >= 2) {
          String studentName = row[0]?.value.toString().trim() ?? '';
          String studentId = row[1]?.value.toString().trim() ?? '';

          if (studentName.isNotEmpty && studentId.isNotEmpty) {
            importedStudents.add(Student(studentName: studentName, studentId: studentId, courseId: widget.courseId));
          }
        }
      }
    }

    for (var student in importedStudents) {
      await DatabaseHelper.instance.insertStudent(student);
    }

    _loadStudents(); // Refresh the student list
  }

  // Function to handle press and hold for selecting students
  void _onStudentSelected(int studentId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedStudents.add(studentId);
      } else {
        _selectedStudents.remove(studentId);
      }
      _isSelecting = _selectedStudents.isNotEmpty; // Activate selection mode
    });
  }

  // Exit selection mode
  void _exitSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedStudents.clear(); // Clear selected students
    });
  }

  // Select or deselect all students
  void _toggleSelectAll(bool isSelectAll) {
    setState(() {
      _selectedStudents = isSelectAll
          ? _students.map((student) => student.id!).toList() // Select all student IDs
          : [];
      _isSelecting = _selectedStudents.isNotEmpty;
    });
  }

  // Edit selected student
  void _editStudent(Student student) {
    final TextEditingController nameController =
    TextEditingController(text: student.studentName);
    final TextEditingController idController =
    TextEditingController(text: student.studentId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Student'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Student Name'),
              ),
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
            ],
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
                String studentName = nameController.text;
                String studentId = idController.text;
                if (studentName.isNotEmpty && studentId.isNotEmpty) {
                  await DatabaseHelper.instance.updateStudent({
                    'id': student.id,
                    'student_name': studentName,
                    'student_id': studentId,
                  });
                  _loadStudents();
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Confirm deletion of selected students
  void _confirmDeleteSelectedStudents() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Students'),
          content: const Text(
              'Are you sure you want to delete the selected students? This action cannot be undone.'),
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
                for (var studentId in _selectedStudents) {
                  await DatabaseHelper.instance.deleteStudent(studentId);
                }
                _exitSelectionMode(); // Exit selection mode after deletion
                _loadStudents();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Show options dialog for adding a student or importing from CSV/Excel
  void _showOptionsDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add Student'),
              onTap: () {
                Navigator.of(context).pop();
                _addStudent(); // Add student manually
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import from CSV/Excel'),
              onTap: () {
                Navigator.of(context).pop();
                _importFromCSVExcel(); // Import students from CSV/Excel
              },
            ),
          ],
        );
      },
    );
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
        title: const Text('Students'),
        actions: _isSelecting
            ? [
          Checkbox(
            value: _selectedStudents.length == _students.length &&
                _students.isNotEmpty,
            onChanged: (value) => _toggleSelectAll(value ?? false),
          ),
        ]
            : [],
      ),
      body: Column(
        children: [
          Expanded(
            child: _students.isEmpty
                ? const Center(child: Text('No students available.'))
                : ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final isSelected =
                _selectedStudents.contains(student.id);
                return ListTile(
                  leading: _isSelecting
                      ? Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      _onStudentSelected(student.id!, value ?? false);
                    },
                  )
                      : null,
                  title: Text('Name: ${student.studentName}'),
                  subtitle: Text('ID: ${student.studentId}'),
                  selected: isSelected,
                  selectedTileColor: Colors.teal.withOpacity(0.3),
                  onLongPress: () {
                    _onStudentSelected(student.id!, !isSelected);
                  },
                  onTap: () {
                    if (_isSelecting) {
                      _onStudentSelected(student.id!, !isSelected);
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
        onPressed: _showOptionsDialog,
        child: const Icon(Icons.add),
      )
          : null,
      bottomNavigationBar: _isSelecting ? _buildActionButtons() : null,
    );
  }

  // Bottom action buttons widget
  Widget _buildActionButtons() {
    bool isMultiple = _selectedStudents.length > 1;
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
                : () => _editStudent(_students.firstWhere(
                    (student) => student.id == _selectedStudents.first)),
            style: ElevatedButton.styleFrom(
              foregroundColor: isMultiple ? Colors.grey : Colors.white,
              backgroundColor: isMultiple ? Colors.grey : Colors.blue,
            ),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: _confirmDeleteSelectedStudents,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
