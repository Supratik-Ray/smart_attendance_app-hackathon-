import 'package:intl/intl.dart';

class Session {
  final String id;
  final String subject;
  final String department;
  final String semester;
  final String section;
  final String startTimeString;
  final String endTimeString;
  final List<dynamic> status;
  late DateTime startTime;
  late DateTime endTime;

  Session({
    required this.id,
    required this.subject,
    required this.department,
    required this.semester,
    required this.section,
    required this.startTimeString,
    required this.endTimeString,
    required this.status,
  }) {
    startTime = _convertToDateTime(startTimeString);
    endTime = _convertToDateTime(endTimeString);
  }

  DateTime _convertToDateTime(String timeString) {
    DateFormat timeFormat = DateFormat("h:mm a");
    DateTime parsedTime = timeFormat.parse(timeString);
    DateTime now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }
}
