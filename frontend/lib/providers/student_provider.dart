import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/models/student.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentProvider extends ChangeNotifier {
  Student? _student;

  Student? get student => _student;

  void setStudent(Map<String, dynamic> json) {
    _student = Student.fromJson(json);
    notifyListeners();
  }

  Future<void> loadStudentFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? userDetails = prefs.getString('user_details');
    if (userDetails != null) {
      print(userDetails);
      _student = Student.fromJson(jsonDecode(userDetails));
      notifyListeners();
    }
  }
}
