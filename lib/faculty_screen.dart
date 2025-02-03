import 'package:flutter/material.dart';
import 'db_helper.dart'; // Import your database helper
import 'courses_page.dart'; // Import the CoursesPage

class FacultyScreen extends StatefulWidget {
  const FacultyScreen({super.key});

  @override
  _FacultyScreenState createState() => _FacultyScreenState();
}

class _FacultyScreenState extends State<FacultyScreen> {
  final _facultyNameController = TextEditingController();
  final _designationController = TextEditingController();
  List<Map<String, dynamic>> _faculties = [];
  List<int> _selectedFaculties = []; // Track selected faculty IDs

  bool _isSelecting = false; // Track if selection mode is active

  @override
  void initState() {
    super.initState();
    _fetchFaculties(); // Fetch the faculties when the screen loads
  }

  // Fetch faculties from the database
  void _fetchFaculties() async {
    _faculties = await DatabaseHelper.instance.getAllFaculties();
    setState(() {}); // Refresh the UI after fetching faculties
  }

  // Open a dialog to add or edit a faculty
  void _openFacultyDialog({Map<String, dynamic>? faculty}) {
    if (faculty != null) {
      _facultyNameController.text = faculty['faculty_name'];
      _designationController.text = faculty['designation'];
    } else {
      _facultyNameController.clear();
      _designationController.clear();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(faculty == null ? 'Add Faculty' : 'Edit Faculty'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _facultyNameController,
                decoration: const InputDecoration(labelText: 'Faculty Name'),
              ),
              TextField(
                controller: _designationController,
                decoration: const InputDecoration(labelText: 'Designation'),
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
              child: Text(faculty == null ? 'Add' : 'Update'),
              onPressed: () {
                if (faculty == null) {
                  _addFaculty();
                } else {
                  _updateFaculty(faculty['id']);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Add a new faculty to the database
  void _addFaculty() async {
    String name = _facultyNameController.text;
    String designation = _designationController.text;

    if (name.isNotEmpty && designation.isNotEmpty) {
      await DatabaseHelper.instance.insertFaculty({
        'faculty_name': name,
        'designation': designation,
      });
      _fetchFaculties(); // Refresh the faculty list after adding
    }
  }

  // Update faculty details in the database
  void _updateFaculty(int id) async {
    String name = _facultyNameController.text;
    String designation = _designationController.text;

    if (name.isNotEmpty && designation.isNotEmpty) {
      await DatabaseHelper.instance.updateFaculty({
        'id': id, // Ensure that this ID is passed correctly
        'faculty_name': name,
        'designation': designation,
      });
      _fetchFaculties(); // Refresh the faculty list after updating
    }
  }

  // Confirm deletion of selected faculties
  void _confirmDeleteSelectedFaculties() {
    if (_selectedFaculties.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text(
                'Are you sure you want to delete the selected faculty? All related information will be permanently deleted.'),
            actions: <Widget>[
              TextButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _deleteSelectedFaculties(); // Proceed with deletion
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Delete selected faculties from the database
  void _deleteSelectedFaculties() async {
    for (var id in _selectedFaculties) {
      await DatabaseHelper.instance.deleteFaculty(id);
    }
    _selectedFaculties.clear();
    _fetchFaculties(); // Refresh the faculty list after deletion
  }

  // Select or deselect faculty
  void _onFacultySelected(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedFaculties.add(id);
      } else {
        _selectedFaculties.remove(id);
      }

      _isSelecting = _selectedFaculties.isNotEmpty;
    });
  }

  // Toggle select all faculties
  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectedFaculties.clear();
      if (value ?? false) {
        _selectedFaculties = _faculties.map((faculty) => faculty['id'] as int).toList();
      }
      _isSelecting = _selectedFaculties.isNotEmpty;
    });
  }

  // Exit selection mode
  void _exitSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedFaculties.clear();
    });
  }

  // Navigate to CoursesPage
  void _goToCoursesPage(int facultyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoursesPage(facultyId: facultyId), // Pass the faculty ID to CoursesPage
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isSelecting
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
        )
            : null,
        title: const Text('Faculty Management'),
        actions: _isSelecting
            ? [
          Checkbox(
            value: _selectedFaculties.length == _faculties.length && _faculties.isNotEmpty,
            onChanged: (value) => _toggleSelectAll(value),
          )
        ]
            : [],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Image.asset(
                'images/faculty.png', // Keep the faculty image where it was
                height: 100,
              ),
            ),
          ),
          Expanded(
            child: _faculties.isEmpty
                ? const Center(child: Text('No Faculties Added'))
                : ListView.builder(
              itemCount: _faculties.length,
              itemBuilder: (context, index) {
                final faculty = _faculties[index];
                final isSelected = _selectedFaculties.contains(faculty['id']);
                return ListTile(
                  onTap: () {
                    _goToCoursesPage(faculty['id']); // Navigate to CoursesPage on tap
                  },
                  onLongPress: () {
                    _onFacultySelected(faculty['id'], !isSelected); // Select on long press
                  },
                  leading: _isSelecting
                      ? Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      _onFacultySelected(faculty['id'], value ?? false);
                    },
                  )
                      : const Icon(Icons.person),
                  title: Text('Name: ${faculty['faculty_name']}'),
                  subtitle: Text('Designation: ${faculty['designation']}'),
                  selected: isSelected,
                  selectedTileColor: Colors.teal.withOpacity(0.3),
                );
              },
            ),
          ),
          if (_isSelecting) _buildActionButtons(),
        ],
      ),
      floatingActionButton: _isSelecting
          ? null
          : FloatingActionButton(
        onPressed: () => _openFacultyDialog(),
        backgroundColor: Colors.teal, // Add new faculty
        child: const Icon(Icons.add),
      ),
    );
  }

  // Bottom action buttons widget
  Widget _buildActionButtons() {
    bool isMultiple = _selectedFaculties.length > 1;
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
                : () => _openFacultyDialog(faculty: _faculties.firstWhere((f) => f['id'] == _selectedFaculties.first)),
            style: ElevatedButton.styleFrom(
              foregroundColor: isMultiple ? Colors.grey : Colors.white, backgroundColor: isMultiple ? Colors.grey : Colors.blue,
            ),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: _confirmDeleteSelectedFaculties,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
