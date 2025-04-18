import 'package:flutter/material.dart';
import 'package:frontend/screens/admin_screens/day_row.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utility/show_snackbar.dart';

class AddRoutine extends StatefulWidget {
  const AddRoutine({super.key});

  @override
  State<AddRoutine> createState() => _AddRoutineState();
}

class _AddRoutineState extends State<AddRoutine> {
  final _formKey = GlobalKey<FormState>();
  List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  Map<String, List<Map<String, String>>> schedule = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
  };

  var _selectedSemester = '1';
  final _sectionController = TextEditingController();
  final _departmentController = TextEditingController();

  // List<dynamic> teachers = [];

  void addClass(String day, Map<String, String> classDetails) {
    setState(() {
      schedule[day]!.add(classDetails);
    });
  }

  void _validateAndAddRoutine() async {
    if (!_formKey.currentState!.validate()) return;

    var sem = _selectedSemester;
    var section = _sectionController.text;
    var department = _departmentController.text;

    List<Future<http.Response>> futures = [];
    for (final day in schedule.keys) {
      for (final session in schedule[day]!) {
        final teacherId = session['teacherId'];

        var url = Uri.parse(
          "https://smart-attendance-app-hackathon.onrender.com/api/routine/$teacherId/$day",
        );

        var future = http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'department': department,
            'semester': sem,
            'section': section,
            'subject': session['subject'],
            'startTime': session['start'],
            'endTime': session['end'],
          }),
        );

        futures.add(future);
      }
    }
    try {
      var responses = await Future.wait(futures);

      if (responses.every((response) => response.statusCode == 201)) {
        if (!mounted) return;
        showSuccessSnackBar(context, "added the routine successfully!");
      }
    } catch (e) {
      print("some error occured!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: ListView(
        children: [
          ...days.map((day) {
            return DayRow(
              day: day,
              classes: schedule[day]!,
              onAddClass: addClass,
            );
          }),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedSemester,
                  items: List.generate(8, (index) {
                    return DropdownMenuItem(
                      value: (index + 1).toString(),
                      child: Text((index + 1).toString()),
                    );
                  }),
                  onChanged: (value) {
                    if (value == null) return;
                    _selectedSemester = value;
                  },
                  validator:
                      (value) =>
                          value == null ? 'Please select a number' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  keyboardType: TextInputType.text,
                  controller: _sectionController,
                  decoration: const InputDecoration(
                    labelText: "section",
                    hintText: "Enter your section",
                    prefixIcon: Icon(Icons.door_back_door),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "please add a section";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  keyboardType: TextInputType.text,
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: "department",
                    hintText: "Enter your department",
                    prefixIcon: Icon(Icons.door_back_door),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "please add a department";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                MaterialButton(
                  onPressed: _validateAndAddRoutine,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Colors.white,
                  minWidth: double.infinity,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    child: Text("Add Routine", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
