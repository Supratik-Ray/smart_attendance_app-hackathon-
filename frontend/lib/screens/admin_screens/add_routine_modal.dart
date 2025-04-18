import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddRoutineModal extends StatefulWidget {
  const AddRoutineModal({
    super.key,
    required this.day,
    required this.onAddClass,
  });

  final String day;
  final void Function(String day, Map<String, String> classDetails) onAddClass;

  @override
  State<AddRoutineModal> createState() => _AddRoutineModalState();
}

class _AddRoutineModalState extends State<AddRoutineModal> {
  List<dynamic> teachers = [];
  String subject = '';
  String startTime = '';
  String endTime = '';

  late String assignedTeacher;

  Future<void> getTeachers() async {
    var url = Uri.parse(
      "https://smart-attendance-app-hackathon.onrender.com/api/teachers/teachers",
    );

    try {
      var res = await http.get(url);
      var data = jsonDecode(res.body);
      teachers = data;
      assignedTeacher = "${data[0]['_id']}-${data[0]['name']}";

      setState(() {});
    } catch (e) {
      print("some error occured: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    getTeachers();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add class for ${widget.day}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Subject'),
              onChanged: (val) => subject = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Start Time'),
              onChanged: (val) => startTime = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'End Time'),
              onChanged: (val) => endTime = val,
            ),
            teachers.isEmpty
                ? const Text("Loading teachers....")
                : DropdownButton<String>(
                  isExpanded: true,
                  value: assignedTeacher,
                  hint: const Text('Select a teacher'),
                  items:
                      teachers.map<DropdownMenuItem<String>>((el) {
                        return DropdownMenuItem<String>(
                          value: "${el['_id']}-${el['name']}",
                          child: Text(el['name']),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        assignedTeacher = value;
                      });
                    }
                  },
                ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (subject.isNotEmpty &&
                startTime.isNotEmpty &&
                endTime.isNotEmpty &&
                assignedTeacher.isNotEmpty) {
              var li = assignedTeacher.split("-");
              widget.onAddClass(widget.day, {
                'subject': subject,
                'start': startTime,
                'end': endTime,
                'teacherName': li[1],
                'teacherId': li[0],
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
