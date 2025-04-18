import 'package:frontend/models/assigned_classes/assigned_class.dart';
import 'package:frontend/models/session.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utility/get_current_day_name.dart';

class Teacher {
  String id;
  String name;
  String email;
  List<AssignedClass> assignedClasses;
  List<Session> routine = [];

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.assignedClasses,
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

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      assignedClasses:
          (json['assignedClasses'] as List<dynamic>).map<AssignedClass>((el) {
            var li = el['className'].split('-');
            String sem = li[0];
            String section = li[1];
            return AssignedClass(
              semester: sem,
              section: section,
              subject: el['subject'],
              dept: el['department'],
            );
          }).toList(),
    );
  }
}
