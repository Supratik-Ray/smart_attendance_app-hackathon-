import 'package:flutter/material.dart';
import 'package:frontend/models/assigned_classes/assigned_class.dart';
import 'package:frontend/models/assigned_classes/assigned_classes.dart';
import 'package:frontend/providers/teacher_provider.dart';
import 'package:frontend/screens/teacher_screens/class_summary.dart';
import 'package:frontend/widgets/teacher_widgets/class_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

class ClassesList extends StatefulWidget {
  const ClassesList({super.key});

  @override
  State<ClassesList> createState() => _ClassesListState();
}

class _ClassesListState extends State<ClassesList> {
  void _selectClass(subject, className) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) {
          return ClassSummary(subject: subject, className: className);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    TeacherProvider teacherProvider = Provider.of<TeacherProvider>(context);
    var assignedClasses = teacherProvider.teacher!.assignedClasses;
    return assignedClasses.isEmpty
        ? const Center(
          child: Text("No classes found!", style: TextStyle(fontSize: 20)),
        )
        : Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: assignedClasses.length,
                  itemBuilder: (ctx, index) {
                    final classItem = assignedClasses[index];
                    return ClassCard(
                      subject: classItem.subject,
                      semester: classItem.semester,
                      section: classItem.section,
                      dept: classItem.dept,
                      onSelectclassItem: _selectClass,
                    );
                  },
                ),
              ),
            ],
          ),
        );
  }
}
