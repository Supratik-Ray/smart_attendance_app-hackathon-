import 'package:flutter/material.dart';
import 'package:frontend/widgets/teacher_widgets/attendance_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utility/show_snackbar.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    super.key,
    required this.section,
    required this.subject,
    required this.onAttendanceGiven,
  });
  final String section;
  final String subject;
  final void Function() onAttendanceGiven;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> students = [];
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchStudents(widget.section);
  }

  Future<void> fetchStudents(String section) async {
    var url = Uri.parse(
      "https://smart-attendance-app-hackathon.onrender.com/api/students/BCA/4-B",
    );

    var res = await http.get(url);

    if (res.statusCode == 200) {
      var data = jsonDecode(res.body);

      for (final student in data) {
        student['is_present'] = null;
      }

      students = data;
      setState(() {});
    } else {
      print("some error occured");
    }
  }

  Future<void> submitAttendance() async {
    setState(() {
      isSubmitting = true;
    });

    var url = Uri.parse(
      "https://smart-attendance-app-hackathon.onrender.com/api/attendance",
    );

    List<Future<http.Response>> futures = [];

    for (final student in students) {
      futures.add(
        http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'studentName': student['name'],
            'studentRoll': student['roll'],
            'dept': student['dept'],
            'className': student['className'],
            'subject': widget.subject,
            'isPresent': student['is_present'] ?? false,
          }),
        ),
      );
    }

    final responses = await Future.wait(futures);

    // Check if all responses were successful
    final allSuccessful = responses.every((res) => res.statusCode == 201);

    if (!mounted) return;

    if (allSuccessful) {
      showSuccessSnackBar(
        context,
        "Attendance submitted successfully for all students!",
      );
      widget.onAttendanceGiven();
      Navigator.pop(context);
    }

    setState(() {
      isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return students.isEmpty || isSubmitting
        ? const Center(child: CircularProgressIndicator())
        : Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people),
                  const SizedBox(width: 8),
                  Text(
                    "Attendance for class ${widget.section}",
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (ctx, index) {
                      final student = students[index];
                      return AttendanceTile(
                        student: student,
                        isPresent: student['is_present'],
                        onChanged: (val) {
                          setState(() {
                            students[index]['is_present'] = val;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: submitAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text("Submit"),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error.withAlpha(180),
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text("Cancel"),
                  ),
                ],
              ),
            ],
          ),
        );
  }
}
