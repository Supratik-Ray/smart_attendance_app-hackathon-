String getCurrentDayName() {
  DateTime now = DateTime.now();
  List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  String currentDayName = weekdays[now.weekday - 1];
  return currentDayName;
}
