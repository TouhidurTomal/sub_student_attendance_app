class Student {
  int? id; // Make id nullable
  String studentName;
  String studentId;
  int courseId;

  Student({
    this.id, // id is now optional
    required this.studentName,
    required this.studentId,
    required this.courseId,
  });

  // Convert Student object to Map (for database insertion)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_name': studentName,
      'student_id': studentId,
      'course_id': courseId,
    };
  }

  // Create Student object from a Map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      studentName: map['student_name'],
      studentId: map['student_id'],
      courseId: map['course_id'],
    );
  }
}
