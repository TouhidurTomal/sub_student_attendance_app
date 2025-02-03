import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "attendance_app.db";
  static const _databaseVersion = 1;

  static const tableFaculties = 'faculties';
  static const tableSemesters = 'semesters';
  static const tableCourses = 'courses';
  static const tableStudents = 'students';
  static const tableAttendance = 'attendance';
  static const tableCTAssignment = 'ct_assignment';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableFaculties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        faculty_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSemesters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semester_name TEXT NOT NULL,
        faculty_id INTEGER NOT NULL,
        FOREIGN KEY (faculty_id) REFERENCES $tableFaculties(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCourses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_name TEXT NOT NULL,
        semester_id INTEGER NOT NULL,
        FOREIGN KEY (semester_id) REFERENCES $tableSemesters(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableStudents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_name TEXT NOT NULL,
        student_id TEXT NOT NULL,
        course_id INTEGER NOT NULL,
        FOREIGN KEY (course_id) REFERENCES $tableCourses(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableAttendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        attendance_date TEXT NOT NULL,
        student_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (course_id) REFERENCES $tableCourses(id),
        FOREIGN KEY (student_id) REFERENCES $tableStudents(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCTAssignment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        ct_date TEXT NOT NULL,
        total_marks INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        obtained_marks INTEGER,
        status TEXT NOT NULL,
        FOREIGN KEY (course_id) REFERENCES $tableCourses(id),
        FOREIGN KEY (student_id) REFERENCES $tableStudents(id)
      )
    ''');
  }

  // Example CRUD Operations

  // Insert into faculties table
  Future<int> insertFaculty(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableFaculties, row);
  }

  // Insert into semesters table
  Future<int> insertSemester(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableSemesters, row);
  }

  // Insert into courses table
  Future<int> insertCourse(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableCourses, row);
  }

  // Insert into students table
  Future<int> insertStudent(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableStudents, row);
  }

  // Insert into attendance table
  Future<int> insertAttendance(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableAttendance, row);
  }

  // Insert into ct_assignment table
  Future<int> insertCTAssignment(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableCTAssignment, row);
  }

  // Get all faculties
  Future<List<Map<String, dynamic>>> getAllFaculties() async {
    Database db = await instance.database;
    return await db.query(tableFaculties);
  }

  // Get all semesters for a faculty
  Future<List<Map<String, dynamic>>> getSemestersByFaculty(int facultyId) async {
    Database db = await instance.database;
    return await db.query(tableSemesters, where: 'faculty_id = ?', whereArgs: [facultyId]);
  }

  // Get all courses for a semester
  Future<List<Map<String, dynamic>>> getCoursesBySemester(int semesterId) async {
    Database db = await instance.database;
    return await db.query(tableCourses, where: 'semester_id = ?', whereArgs: [semesterId]);
  }

  // Get all students in a course
  Future<List<Map<String, dynamic>>> getStudentsByCourse(int courseId) async {
    Database db = await instance.database;
    return await db.query(tableStudents, where: 'course_id = ?', whereArgs: [courseId]);
  }

  // Get attendance for a course on a specific date
  Future<List<Map<String, dynamic>>> getAttendanceByDate(int courseId, String date) async {
    Database db = await instance.database;
    return await db.query(tableAttendance, where: 'course_id = ? AND attendance_date = ?', whereArgs: [courseId, date]);
  }

  // Get CT/Assignment data for a course
  Future<List<Map<String, dynamic>>> getCTAssignmentsByCourse(int courseId) async {
    Database db = await instance.database;
    return await db.query(tableCTAssignment, where: 'course_id = ?', whereArgs: [courseId]);
  }
}
