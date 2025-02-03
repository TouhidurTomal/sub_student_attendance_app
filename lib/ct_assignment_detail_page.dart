import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'db_helper.dart'; // Import your database helper class

class CTAssignmentDetailPage extends StatefulWidget {
  final int assignmentId;
  final String assignmentName;
  final int courseId;

  const CTAssignmentDetailPage({
    super.key,
    required this.assignmentId,
    required this.assignmentName,
    required this.courseId,
  });

  @override
  _CTAssignmentDetailPageState createState() => _CTAssignmentDetailPageState();
}

class _CTAssignmentDetailPageState extends State<CTAssignmentDetailPage> {
  List<Map<String, dynamic>> _students = [];
  final Map<int, int?> _studentMarks = {}; // Store student marks by studentId (nullable)
  int? _fullMarks; // Store full marks value
  DateTime? _selectedDate; // Store assignment date

  final TextEditingController _fullMarksController = TextEditingController(); // Controller for Full Marks input

  @override
  void initState() {
    super.initState();
    _loadAssignmentDetails(); // Load the full_marks and date for this assignment
    _loadStudents(); // Load the students and their marks
  }

  // Function to load assignment details (full marks and date)
// Load assignment details (full marks and date)
  void _loadAssignmentDetails() async {
    try {
      List<Map<String, dynamic>> assignments = await DatabaseHelper.instance.getCTAssignmentsByCourse(widget.courseId);

      if (assignments.isNotEmpty) {
        var currentAssignment = assignments.firstWhere((assignment) => assignment['id'] == widget.assignmentId, orElse: () => {});

        setState(() {
          _fullMarks = currentAssignment['full_marks'];
          _fullMarksController.text = _fullMarks != null ? _fullMarks.toString() : ''; // Display full marks in the TextField
          _selectedDate = DateTime.tryParse(currentAssignment['date'] ?? '') ?? DateTime.now();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading assignment details: $e')),
      );
    }
  }

  // Function to load students of the course and their marks from the database
  void _loadStudents() async {
    try {
      // Load students for the course
      List<Map<String, dynamic>> students = await DatabaseHelper.instance.getStudentsByCourse(widget.courseId);
      setState(() {
        _students = students;
      });

      // Load existing student marks for this assignment
      List<Map<String, dynamic>> existingMarks = await DatabaseHelper.instance.getStudentMarksByAssignment(widget.assignmentId);
      setState(() {
        for (var mark in existingMarks) {
          _studentMarks[mark['student_id']] = mark['obtained_marks'];
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
      );
    }
  }

// Function to save student marks and update full marks
  void _saveMarks() async {
    try {
      // Parse and validate full marks
      _fullMarks = int.tryParse(_fullMarksController.text);

      // If full marks is not provided, set it to a default value like 0 or skip the validation
      if (_fullMarks == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid Full Marks value.')),
        );
        return;
      }

      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date.')),
        );
        return;
      }

      // Save full marks and date to the database
      await DatabaseHelper.instance.updateCTAssignment({
        'id': widget.assignmentId,
        'full_marks': _fullMarks!,  // Update full marks
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!), // Save formatted date
      });

      // Save student marks
      for (var entry in _studentMarks.entries) {
        int studentId = entry.key;
        int? marks = entry.value;

        if (marks != null) {
          if (marks > _fullMarks!) {
            marks = _fullMarks!; // Ensure marks do not exceed full marks
          }

          // Insert or update marks in the database
          await DatabaseHelper.instance.insertOrUpdateStudentMarks({
            'student_id': studentId,
            'assignment_id': widget.assignmentId,
            'obtained_marks': marks,
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save marks: $e')),
      );
    }
  }


  // Function to select a date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.assignmentName} Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                // Full Marks input field (Editable now)
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _fullMarksController,
                    decoration: const InputDecoration(labelText: 'Full Marks'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                // Date picker with calendar icon (Half width)
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 10),
                          Text(_selectedDate == null
                              ? 'Select Date'
                              : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return ListTile(
                    title: Text(student['student_name']),
                    trailing: SizedBox(
                      width: 60,
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Marks'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          int parsedValue = int.tryParse(value) ?? 0;
                          if (_fullMarks != null && parsedValue > _fullMarks!) {
                            parsedValue = _fullMarks!;
                          }
                          _studentMarks[student['id']] = parsedValue;
                        },
                        controller: TextEditingController(
                          text: _studentMarks[student['id']] != null
                              ? (_studentMarks[student['id']]!.toString())
                              : '',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveMarks,
              child: const Text('Save Marks'),
            ),
          ],
        ),
      ),
    );
  }
}
