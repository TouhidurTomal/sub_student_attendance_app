import 'package:flutter/material.dart';
import 'db_helper.dart'; // Import your DatabaseHelper
import 'ct_assignment_detail_page.dart'; // Correct import for CTAssignmentDetailPage

class CTAssignmentPage extends StatefulWidget {
  final int courseId;
  final String courseName;

  const CTAssignmentPage({super.key, required this.courseId, required this.courseName});

  @override
  _CTAssignmentPageState createState() => _CTAssignmentPageState();
}

class _CTAssignmentPageState extends State<CTAssignmentPage> {
  List<Map<String, dynamic>> _ctAssignments = [];
  List<int> _selectedAssignments = [];
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _loadCTAssignments();
  }

  // Function to load CT/Assignments from the database in ascending order
  void _loadCTAssignments() async {
    List<Map<String, dynamic>> assignments =
    await DatabaseHelper.instance.getCTAssignmentsByCourse(widget.courseId);
    setState(() {
      _ctAssignments = assignments;
    });
  }

  // Function to add a new CT/Assignment
  void _addCTAssignment() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New CT/Assignment'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Assignment Name'),
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
                String assignmentName = nameController.text;

                if (assignmentName.isNotEmpty) {
                  // Insert assignment without worrying about full_marks
                  await DatabaseHelper.instance.insertCTAssignment({
                    'assignment_name': assignmentName,
                    'course_id': widget.courseId,
                    'full_marks': 0, // Or set to 0 if you prefer
                  });

                  _loadCTAssignments(); // Refresh the list after adding
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assignment name cannot be empty.')),
                  );
                }

                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  // Function to navigate to the assignment details page
  void _navigateToDetailsPage(int assignmentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CTAssignmentDetailPage(
          assignmentId: assignmentId,
          assignmentName: _ctAssignments.firstWhere((assignment) => assignment['id'] == assignmentId)['assignment_name'],
          courseId: widget.courseId, // Add this line to pass courseId
        ),
      ),
    );
  }


  // Function to edit a CT/Assignment
  void _editCTAssignment() {
    if (_selectedAssignments.length == 1) {
      final assignment = _ctAssignments.firstWhere((element) => element['id'] == _selectedAssignments[0]);
      final TextEditingController nameController = TextEditingController(text: assignment['assignment_name']);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Edit CT/Assignment'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Assignment Name'),
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
                  String updatedName = nameController.text;
                  if (updatedName.isNotEmpty) {
                    await DatabaseHelper.instance.updateCTAssignment({
                      'id': assignment['id'],
                      'assignment_name': updatedName
                    });
                    _loadCTAssignments();
                  }
                  if (mounted) Navigator.of(context).pop();
                  _exitSelectionMode();
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Function to delete selected CT/Assignments
  void _deleteCTAssignments() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete CT/Assignment(s)'),
          content: const Text('Are you sure you want to delete the selected assignment(s)?'),
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
                for (int id in _selectedAssignments) {
                  await DatabaseHelper.instance.deleteCTAssignment(id);
                }
                _loadCTAssignments();
                if (mounted) Navigator.of(context).pop();
                _exitSelectionMode();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to exit selection mode
  void _exitSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedAssignments.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.courseName} CT/Assignments'),
        actions: _isSelecting
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _selectedAssignments.length == 1 ? _editCTAssignment : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCTAssignments,
          ),
          Checkbox(
            value: _selectedAssignments.length == _ctAssignments.length && _ctAssignments.isNotEmpty,
            onChanged: (value) {
              setState(() {
                _selectedAssignments = value!
                    ? _ctAssignments.map<int>((e) => e['id'] as int).toList()
                    : [];
              });
            },
          ),
        ]
            : null,
        leading: _isSelecting
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
        )
            : null,
      ),
      body: _ctAssignments.isEmpty
          ? const Center(child: Text('No CT/Assignments available.'))
          : ListView.builder(
        itemCount: _ctAssignments.length,
        itemBuilder: (context, index) {
          final assignment = _ctAssignments[index];
          final isSelected = _selectedAssignments.contains(assignment['id']);
          return ListTile(
            leading: _isSelecting
                ? Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedAssignments.add(assignment['id']);
                  } else {
                    _selectedAssignments.remove(assignment['id']);
                  }
                });
              },
            )
                : null,
            title: Text(assignment['assignment_name']),
            onTap: () {
              if (_isSelecting) {
                setState(() {
                  if (isSelected) {
                    _selectedAssignments.remove(assignment['id']);
                  } else {
                    _selectedAssignments.add(assignment['id']);
                  }
                });
              } else {
                _navigateToDetailsPage(assignment['id']); // Navigate to details page
              }
            },
            onLongPress: () {
              setState(() {
                _isSelecting = true;
                _selectedAssignments.add(assignment['id']);
              });
            },
          );
        },
      ),
      floatingActionButton: !_isSelecting
          ? FloatingActionButton(
        onPressed: _addCTAssignment,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
