import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'student.dart';

class DatabaseHelper {
  static const _databaseName = "faculty_management.db";
  static const _databaseVersion = 11;

  // Table names
  static const tableFaculties = 'faculties';
  static const tableSemesters = 'semesters';
  static const tableCourses = 'courses';
  static const tableStudents = 'students';
  static const tableAttendance = 'attendance';
  static const tableAttendanceRecords = 'attendance_records';
  static const tableCTAssignments = 'ct_assignments';
  static const tableStudentMarks = 'student_marks';

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
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableFaculties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        faculty_name TEXT NOT NULL,
        designation TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSemesters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semester_name TEXT NOT NULL,
        faculty_id INTEGER NOT NULL,
        FOREIGN KEY (faculty_id) REFERENCES $tableFaculties(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCourses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_name TEXT NOT NULL,
        semester_id INTEGER NOT NULL,
        FOREIGN KEY (semester_id) REFERENCES $tableSemesters(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableStudents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_name TEXT NOT NULL,
        student_id TEXT NOT NULL,
        course_id INTEGER NOT NULL,
        FOREIGN KEY (course_id) REFERENCES $tableCourses(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableAttendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        attendance_date TEXT NOT NULL,
        FOREIGN KEY (course_id) REFERENCES $tableCourses(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableAttendanceRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        student_id INTEGER NOT NULL,
        course_id INTEGER NOT NULL,
        status INTEGER NOT NULL,
        FOREIGN KEY (student_id) REFERENCES $tableStudents(id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES $tableCourses(id) ON DELETE CASCADE
      )
    ''');

    // Modify full_marks to allow NULL
    await db.execute('''
  CREATE TABLE $tableCTAssignments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    assignment_name TEXT NOT NULL,
    course_id INTEGER NOT NULL,
    full_marks INTEGER,  -- Nullable full_marks column
    date TEXT,  -- Nullable date column
    FOREIGN KEY (course_id) REFERENCES $tableCourses(id) ON DELETE CASCADE
  );
''');


    await db.execute('''
      CREATE TABLE $tableStudentMarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        assignment_id INTEGER NOT NULL,
        obtained_marks INTEGER NOT NULL,
        FOREIGN KEY (student_id) REFERENCES $tableStudents(id) ON DELETE CASCADE,
        FOREIGN KEY (assignment_id) REFERENCES $tableCTAssignments(id) ON DELETE CASCADE
      )
    ''');

    print("Database created with all tables.");
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 11) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS temp_ct_assignments AS SELECT * FROM $tableCTAssignments;
    ''');

      await db.execute('DROP TABLE IF EXISTS $tableCTAssignments');

      await db.execute('''
      CREATE TABLE $tableCTAssignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assignment_name TEXT NOT NULL,
        course_id INTEGER NOT NULL,
        full_marks INTEGER, -- Allow full_marks to be nullable
        date TEXT,
        FOREIGN KEY (course_id) REFERENCES $tableCourses(id) ON DELETE CASCADE
      );
    ''');

      await db.execute('''
      INSERT INTO $tableCTAssignments (id, assignment_name, course_id, full_marks, date)
      SELECT id, assignment_name, course_id, full_marks, date FROM temp_ct_assignments;
    ''');

      await db.execute('DROP TABLE IF EXISTS temp_ct_assignments');
    }
  }


  // CRUD Operations for Faculties
  Future<int> insertFaculty(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableFaculties, row);
  }

  Future<List<Map<String, dynamic>>> getAllFaculties() async {
    Database db = await instance.database;
    return await db.query(tableFaculties);
  }

  Future<int> updateFaculty(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(tableFaculties, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteFaculty(int id) async {
    Database db = await instance.database;
    return await db.delete(tableFaculties, where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Operations for Semesters
  Future<int> insertSemester(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableSemesters, row);
  }

  Future<List<Map<String, dynamic>>> getSemestersByFaculty(int facultyId) async {
    Database db = await instance.database;
    return await db.query(tableSemesters, where: 'faculty_id = ?', whereArgs: [facultyId]);
  }

  Future<int> updateSemester(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(tableSemesters, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSemester(int id) async {
    Database db = await instance.database;
    return await db.delete(tableSemesters, where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Operations for Courses
  Future<int> insertCourse(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableCourses, row);
  }

  Future<List<Map<String, dynamic>>> getCoursesBySemester(int semesterId) async {
    Database db = await instance.database;
    return await db.query(tableCourses, where: 'semester_id = ?', whereArgs: [semesterId]);
  }

  Future<int> updateCourse(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(tableCourses, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCourse(int id) async {
    Database db = await instance.database;
    return await db.delete(tableCourses, where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Operations for Students
  Future<int> insertStudent(Student student) async {
    Database db = await instance.database;
    return await db.insert('students', {
      'student_name': student.studentName,
      'student_id': student.studentId,
      'course_id': student.courseId,
    });
  }

  Future<List<Map<String, dynamic>>> getStudentsByCourse(int courseId) async {
    Database db = await instance.database;
    return await db.query('students', where: 'course_id = ?', whereArgs: [courseId]);
  }

  Future<int> updateStudent(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(tableStudents, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteStudent(int id) async {
    Database db = await instance.database;
    return await db.delete(tableStudents, where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Operations for Attendance
  Future<int> insertAttendance(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableAttendance, row);
  }

  Future<List<Map<String, dynamic>>> getAttendanceByCourse(int courseId) async {
    Database db = await instance.database;
    return await db.query(tableAttendance, where: 'course_id = ?', whereArgs: [courseId], orderBy: 'attendance_date ASC');
  }

  Future<int> updateAttendance(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(tableAttendance, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAttendance(int id) async {
    Database db = await instance.database;
    return await db.delete(tableAttendance, where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Operations for Attendance Records
  Future<int> insertAttendanceRecord(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableAttendanceRecords, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertOrUpdateAttendanceRecord(Map<String, dynamic> data) async {
    Database db = await instance.database;

    List<Map<String, dynamic>> result = await db.query(
      'attendance_records',
      where: 'student_id = ? AND date = ? AND course_id = ?',
      whereArgs: [data['student_id'], data['date'], data['course_id']],
    );

    if (result.isEmpty) {
      return await db.insert('attendance_records', data);
    } else {
      return await db.update(
        'attendance_records',
        data,
        where: 'student_id = ? AND date = ? AND course_id = ?',
        whereArgs: [data['student_id'], data['date'], data['course_id']],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceRecordsByDateAndCourse(String date, int courseId) async {
    Database db = await instance.database;
    return await db.rawQuery('''
      SELECT s.student_name, s.student_id, ar.status
      FROM students AS s
      JOIN attendance_records AS ar ON s.id = ar.student_id
      WHERE ar.date = ? AND ar.course_id = ?
    ''', [date, courseId]);
  }

  Future<List<Map<String, dynamic>>> getAttendanceRecordsByCourse(int courseId) async {
    Database db = await instance.database;
    return await db.query(tableAttendanceRecords, where: 'course_id = ?', whereArgs: [courseId], orderBy: 'date ASC');
  }

  // CRUD Operations for CT/Assignments
  Future<int> insertCTAssignment(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableCTAssignments, row);
  }


  Future<List<Map<String, dynamic>>> getCTAssignmentsByCourse(int courseId) async {
    Database db = await instance.database;
    return await db.query(tableCTAssignments, where: 'course_id = ?', whereArgs: [courseId], orderBy: 'assignment_name ASC');
  }

  Future<int> updateCTAssignment(Map<String, dynamic> data) async {
    Database db = await instance.database;
    return await db.update(
      tableCTAssignments,
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  }

  Future<int> deleteCTAssignment(int id) async {
    Database db = await instance.database;
    return await db.delete(tableCTAssignments, where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Operations for Student Marks
  Future<int> insertOrUpdateStudentMarks(Map<String, dynamic> data) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      tableStudentMarks,
      where: 'student_id = ? AND assignment_id = ?',
      whereArgs: [data['student_id'], data['assignment_id']],
    );

    if (result.isEmpty) {
      return await db.insert(tableStudentMarks, data);
    } else {
      return await db.update(
        tableStudentMarks,
        {'obtained_marks': data['obtained_marks']},
        where: 'student_id = ? AND assignment_id = ?',
        whereArgs: [data['student_id'], data['assignment_id']],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getStudentMarksByAssignment(int assignmentId) async {
    Database db = await instance.database;
    return await db.query(tableStudentMarks, where: 'assignment_id = ?', whereArgs: [assignmentId]);
  }

  Future<List<Map<String, dynamic>>> getCTRecordsByCourse(int courseId) async {
    Database db = await instance.database;
    return await db.rawQuery('''
      SELECT s.student_name, s.student_id, sm.obtained_marks, ct.assignment_name
      FROM students AS s
      JOIN student_marks AS sm ON s.id = sm.student_id
      JOIN ct_assignments AS ct ON sm.assignment_id = ct.id
      WHERE ct.course_id = ?
      ORDER BY s.student_name ASC
    ''', [courseId]);
  }
}
