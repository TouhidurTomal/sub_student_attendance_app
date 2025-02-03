import 'package:flutter/material.dart';
import 'db_helper.dart';

class FacultyScreen extends StatefulWidget {
  @override
  _FacultyScreenState createState() => _FacultyScreenState();
}

class _FacultyScreenState extends State<FacultyScreen> {
  final _facultyController = TextEditingController();
  List<Map<String, dynamic>> _faculties = [];

  @override
  void initState() {
    super.initState();
    _fetchFaculties();
  }

  // Fetch faculties from the database
  void _fetchFaculties() async {
    _faculties = await DatabaseHelper.instance.getAllFaculties();
    setState(() {});
  }

  // Add a new faculty
  void _addFaculty() async {
    String facultyName = _facultyController.text;
    if (facultyName.isNotEmpty) {
      await DatabaseHelper.instance.insertFaculty({'faculty_name': facultyName});
      _facultyController.clear();
      _fetchFaculties();  // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Faculties'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _facultyController,
              decoration: InputDecoration(labelText: 'Faculty Name'),
            ),
          ),
          ElevatedButton(
            onPressed: _addFaculty,
            child: Text('Add Faculty'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _faculties.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_faculties[index]['faculty_name']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
