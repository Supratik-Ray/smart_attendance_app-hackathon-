import 'package:frontend/models/session.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utility/get_current_day_name.dart';

class Student {
  String id;
  String name;
  String roll;
  String className;
  String dept;
  String email;
  bool isInClass;
  List<Session> routine = [];

  Student({
    required this.id,
    required this.name,
    required this.roll,
    required this.className,
    required this.dept,
    required this.email,
    required this.isInClass,
  });

  Future<void> initRoutine() async {
    final day = getCurrentDayName();
    var url = Uri.parse(
      "https://smart-attendance-app-hackathon.onrender.com/api/routine/$id/$day",
    );

    try {
      var res = await http.get(url);
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        routine =
            (data['routine'] as List<dynamic>)
                .map(
                  (sessionData) => Session(
                    id: sessionData['_id'],
                    subject: sessionData['subject'],
                    department: sessionData['department'],
                    semester: sessionData['semester'],
                    section: sessionData['section'],
                    startTimeString: sessionData['startTime'],
                    endTimeString: sessionData['endTime'],
                    status: sessionData['status'],
                  ),
                )
                .toList();
      }
    } catch (e) {
      print("some error occured : $e");
    }
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      roll: json['roll'],
      className: json['className'],
      dept: json['dept'],
      isInClass: json['is_in_class'],
    );
  }
}
