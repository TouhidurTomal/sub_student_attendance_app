import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart'; // For app directory access
import 'package:open_file/open_file.dart'; // For opening files after creation
import 'package:file_picker/file_picker.dart'; // For picking file save location
import 'dart:io'; // For file IO
import 'db_helper.dart';
import 'attendance_taker.dart'; // Import AttendanceTakerPage

class AttendancePage extends StatefulWidget {
  final int courseId;
  final String courseName;

  const AttendancePage({super.key, required this.courseId, required this.courseName});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<Map<String, dynamic>> _attendanceDates = [];
  List<int> _selectedDates = [];
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _loadAttendanceDates();
  }

  void _loadAttendanceDates() async {
    List<Map<String, dynamic>> dates = await DatabaseHelper.instance.getAttendanceByCourse(widget.courseId);
    setState(() {
      _attendanceDates = dates;
    });
  }

  void _addAttendanceDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      await DatabaseHelper.instance.insertAttendance({
        'course_id': widget.courseId,
        'attendance_date': formattedDate,
      });
      _loadAttendanceDates();
    }
  }

  // Function to handle press and hold for selecting dates
  void _onDateSelected(int dateId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedDates.add(dateId);
      } else {
        _selectedDates.remove(dateId);
      }
      _isSelecting = _selectedDates.isNotEmpty;
    });
  }

  // Exit selection mode
  void _exitSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedDates.clear();
    });
  }

  // Select or deselect all dates
  void _toggleSelectAll(bool isSelectAll) {
    setState(() {
      _selectedDates = isSelectAll
          ? _attendanceDates.map((date) => date['id'] as int).toList()
          : [];
      _isSelecting = _selectedDates.isNotEmpty;
    });
  }

  // Function to edit selected date
  void _editDate(Map<String, dynamic> date) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(date['attendance_date']),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      await DatabaseHelper.instance.updateAttendance({
        'id': date['id'],
        'attendance_date': formattedDate,
      });
      _loadAttendanceDates(); // Refresh dates after editing
    }
  }

  // Confirm deletion of selected dates
  void _confirmDeleteSelectedDates() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Dates'),
          content: const Text('Are you sure you want to delete the selected dates?'),
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
                for (var dateId in _selectedDates) {
                  await DatabaseHelper.instance.deleteAttendance(dateId);
                }
                _exitSelectionMode();
                _loadAttendanceDates();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to create and download CSV file to a user-chosen directory
  Future<void> _downloadCSVFile(String attendanceDate) async {
    StringBuffer csvData = StringBuffer();
    // Add headers
    csvData.writeln('${widget.courseName}');
    csvData.writeln('Attendance Date: $attendanceDate');
    csvData.writeln('Student Name, Student ID, Attendance Status');

    // Fetch the attendance records for the selected date
    List<Map<String, dynamic>> attendanceRecords = await DatabaseHelper.instance
        .getAttendanceRecordsByDateAndCourse(attendanceDate, widget.courseId);

    // Append attendance data for each student in CSV format
    for (var record in attendanceRecords) {
      String status = record['status'] == 1 ? 'Present' : 'Absent';
      csvData.writeln('${record['student_name']},${record['student_id']},$status');
    }

    // Let user select the directory where they want to save the file
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      String path = '$selectedDirectory/attendance_${widget.courseName}_$attendanceDate.csv';

      // Save the CSV file
      File file = File(path);
      await file.writeAsString(csvData.toString());

      // Notify user and offer to open the file
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV file saved at $path')));
      await OpenFile.open(path); // Opens the file after saving
    }
  }

  // Function to share CSV file without using share_plus
  Future<void> _shareCSVFile(String attendanceDate) async {
    StringBuffer csvData = StringBuffer();

    // Add headers
    csvData.writeln('${widget.courseName}');
    csvData.writeln('Attendance Date: $attendanceDate');
    csvData.writeln('Student Name, Student ID, Attendance Status');

    // Fetch the attendance records for the selected date
    List<Map<String, dynamic>> attendanceRecords = await DatabaseHelper.instance
        .getAttendanceRecordsByDateAndCourse(attendanceDate, widget.courseId);

    for (var record in attendanceRecords) {
      String status = record['status'] == 1 ? 'Present' : 'Absent';
      csvData.writeln('${record['student_name']},${record['student_id']},$status');
    }

    // Save the file to a temporary location
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = '${tempDir.path}/attendance_${widget.courseName}_$attendanceDate.csv';
    File file = File(tempPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(csvData.toString());

    // Open the file for sharing using system UI
    await OpenFile.open(tempPath);
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
        title: Text('${widget.courseName} Attendance'),
        actions: _isSelecting
            ? [
          Checkbox(
            value: _selectedDates.length == _attendanceDates.length && _attendanceDates.isNotEmpty,
            onChanged: (value) => _toggleSelectAll(value ?? false),
          ),
        ]
            : [],
      ),
      body: Column(
        children: [
          Expanded(
            child: _attendanceDates.isEmpty
                ? const Center(child: Text('No attendance records available.'))
                : ListView.builder(
              itemCount: _attendanceDates.length,
              itemBuilder: (context, index) {
                final date = _attendanceDates[index];
                final isSelected = _selectedDates.contains(date['id']);
                return ListTile(
                  leading: _isSelecting
                      ? Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      _onDateSelected(date['id'], value ?? false);
                    },
                  )
                      : null,
                  title: Text('Date: ${date['attendance_date']}'),
                  selected: isSelected,
                  selectedTileColor: Colors.teal.withOpacity(0.3),
                  onLongPress: () {
                    _onDateSelected(date['id'], !isSelected);
                  },
                  onTap: () {
                    if (_isSelecting) {
                      _onDateSelected(date['id'], !isSelected);
                    } else {
                      // Navigate to AttendanceTakerPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceTakerPage(
                            date: date['attendance_date'],
                            courseId: widget.courseId,
                          ),
                        ),
                      );
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
        onPressed: _addAttendanceDate,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      )
          : null,
      bottomNavigationBar: _isSelecting ? _buildActionButtons() : null,
    );
  }

  // Bottom action buttons widget
  Widget _buildActionButtons() {
    bool isMultiple = _selectedDates.length > 1;
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
                : () => _editDate(
                _attendanceDates.firstWhere((date) => date['id'] == _selectedDates.first)),
            style: ElevatedButton.styleFrom(
              foregroundColor: isMultiple ? Colors.grey : Colors.white,
              backgroundColor: isMultiple ? Colors.grey : Colors.blue,
            ),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: _confirmDeleteSelectedDates,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          ElevatedButton(
            onPressed: _selectedDates.length == 1
                ? () {
              var selectedDate = _attendanceDates.firstWhere((date) => date['id'] == _selectedDates.first)['attendance_date'];
              _downloadCSVFile(selectedDate);
            }
                : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Download'),
          ),
          ElevatedButton(
            onPressed: _selectedDates.length == 1
                ? () {
              var selectedDate = _attendanceDates.firstWhere((date) => date['id'] == _selectedDates.first)['attendance_date'];
              _shareCSVFile(selectedDate);
            }
                : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}
