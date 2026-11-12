import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

// 1. Main application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student CRUD App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const StudentScreen(),
    );
  }
}

// 2. Database helper
class StudentDatabase {
  static final StudentDatabase instance =
  StudentDatabase._privateConstructor();

  StudentDatabase._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final dbPath = p.join(databasePath, 'students.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            course TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // CREATE: Insert a student
  Future<int> insertStudent(
      Map<String, dynamic> student,
      ) async {
    final db = await database;

    return await db.insert(
      'students',
      student,
    );
  }

  // READ: Get all students
  Future<List<Map<String, dynamic>>> getStudents() async {
    final db = await database;

    return await db.query(
      'students',
      orderBy: 'id DESC',
    );
  }

  // UPDATE: Edit a student
  Future<int> updateStudent(
      int id,
      Map<String, dynamic> student,
      ) async {
    final db = await database;

    return await db.update(
      'students',
      student,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE: Remove a student
  Future<int> deleteStudent(int id) async {
    final db = await database;

    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// 3. Student screen
class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  // Read database records and refresh the screen
  Future<void> loadStudents() async {
    final data = await StudentDatabase.instance.getStudents();

    if (!mounted) return;

    setState(() {
      students = data;
    });
  }

  // Add or edit a student
  Future<void> showStudentDialog({
    Map<String, dynamic>? student,
  }) async {
    final nameController = TextEditingController(
      text: student?['name'] ?? '',
    );
    final emailController = TextEditingController(
      text: student?['email'] ?? '',
    );
    final courseController = TextEditingController(
      text: student?['course'] ?? '',
    );

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            student == null ? 'Add Student' : 'Edit Student',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Student Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter student name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: courseController,
                    decoration: const InputDecoration(
                      labelText: 'Course',
                      prefixIcon: Icon(Icons.school),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter course';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final studentData = <String, dynamic>{
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'course': courseController.text.trim(),
                };

                if (student == null) {
                  await StudentDatabase.instance
                      .insertStudent(studentData);
                } else {
                  await StudentDatabase.instance.updateStudent(
                    student['id'] as int,
                    studentData,
                  );
                }

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);
                await loadStudents();
              },
              child: Text(student == null ? 'Save' : 'Update'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    courseController.dispose();
  }

  // Delete a student after confirmation
  Future<void> confirmDelete(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Student'),
          content: const Text(
            'Are you sure you want to delete this student?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await StudentDatabase.instance.deleteStudent(id);
      await loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      body: students.isEmpty
          ? const Center(
        child: Text(
          'No students found.\nTap + to add a student.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                child: Text(
                  student['name']
                      .toString()[0]
                      .toUpperCase(),
                ),
              ),
              title: Text(
                student['name'].toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${student['email']}\n'
                    'Course: ${student['course']}',
              ),
              isThreeLine: true,
              trailing: SizedBox(
                width: 88,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () {
                        showStudentDialog(student: student);
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () {
                        confirmDelete(student['id'] as int);
                      },
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showStudentDialog();
        },
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}