import 'package:flutter/material.dart';
import 'package:frontend/screens/admin_screens/add_routine.dart';
import 'package:frontend/screens/admin_screens/add_teachers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/admin_screens/add_classrooms.dart';
import 'package:frontend/screens/admin_screens/add_students.dart';
import 'package:frontend/login_screen.dart';
import 'package:frontend/screens/student_screens/student_dashboard.dart';
// import 'package:frontend/screens/student_screens/student_notifications.dart';
import 'package:frontend/screens/student_screens/subjects_summary.dart';
import 'package:frontend/screens/teacher_screens/teacher_dashboard.dart';
import 'package:frontend/screens/teacher_screens/classes_list.dart';

enum UserRole { student, parent, teacher, admin }

final List<Map<String, dynamic>> _studentScreens = [
  {
    'widget': const StudentDashboard(),
    'title': 'Dashboard',
    'icon': const Icon(Icons.home),
  },
  {
    'widget': const SubjectsSummary(),
    'title': 'Summary',
    'icon': const Icon(Icons.analytics),
  },
];

final List<Map<String, dynamic>> _teacherScreens = [
  {
    'widget': const TeacherDashboard(),
    'title': 'Dashboard',
    'icon': const Icon(Icons.home),
  },
  {
    'widget': const ClassesList(),
    'title': 'Classes',
    'icon': const Icon(Icons.analytics),
  },
];

final List<Map<String, dynamic>> _adminScreens = [
  {
    'widget': const AddStudents(),
    'title': 'Add Students',
    'icon': const Icon(Icons.people),
  },
  {
    'widget': const AddTeachers(),
    'title': 'Add Teachers',
    'icon': const Icon(Icons.school),
  },
  {
    'widget': const AddClassrooms(),
    'title': 'Add classroom',
    'icon': const Icon(Icons.meeting_room),
  },
  {
    'widget': const AddRoutine(),
    'title': 'Add Routine',
    'icon': const Icon(Icons.calendar_month_rounded),
  },
];

class Layout extends StatefulWidget {
  const Layout({super.key, required this.currentUser});

  final UserRole currentUser;

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  var _currentIndex = 0;

  late final List<Map<String, dynamic>> _activeScreens;

  @override
  void initState() {
    super.initState();
    if (widget.currentUser == UserRole.student) {
      _activeScreens = _studentScreens;
    } else if (widget.currentUser == UserRole.teacher) {
      _activeScreens = _teacherScreens;
    } else {
      _activeScreens = _adminScreens;
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (ctx) {
          return const LoginScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentScreen = _activeScreens[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentScreen['title'],
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: currentScreen['widget'],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          for (final screen in _activeScreens)
            BottomNavigationBarItem(
              icon: screen['icon'],
              label: screen['title'],
            ),
        ],
        currentIndex: _currentIndex,
        onTap:
            (value) => setState(() {
              _currentIndex = value;
            }),
      ),
    );
  }
}
