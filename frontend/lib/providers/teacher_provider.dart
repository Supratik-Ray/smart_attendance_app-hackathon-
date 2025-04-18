import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/models/teacher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherProvider extends ChangeNotifier {
  Teacher? _teacher;

  Teacher? get teacher => _teacher;

  void setTeacher(Map<String, dynamic> json) {
    _teacher = Teacher.fromJson(json);
    notifyListeners();
  }

  Future<void> loadTeacherFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? userDetails = prefs.getString('user_details');
    if (userDetails != null) {
      print(userDetails);
      _teacher = Teacher.fromJson(jsonDecode(userDetails));
      notifyListeners();
    }
  }
}
