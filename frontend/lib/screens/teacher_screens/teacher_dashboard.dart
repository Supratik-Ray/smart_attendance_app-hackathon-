import 'package:flutter/material.dart';
//teacher routine
import 'package:frontend/providers/teacher_provider.dart';
import 'package:frontend/screens/teacher_screens/attendance_screen.dart';

import 'package:frontend/widgets/teacher_widgets/teacher_class_tile.dart';
import 'package:provider/provider.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  Future<void>? _routineFuture;

  showAttendanceModal(String section, String subject, onAttendanceGiven) {
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      builder: (context) {
        return AttendanceScreen(
          section: section,
          subject: subject,
          onAttendanceGiven: onAttendanceGiven,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final teacherProvider = Provider.of<TeacherProvider>(
      context,
      listen: false,
    );
    _routineFuture = teacherProvider.teacher!.initRoutine();
  }

  @override
  Widget build(BuildContext context) {
    TeacherProvider teacherProvider = Provider.of<TeacherProvider>(context);
    final theme = Theme.of(context);
    return FutureBuilder<void>(
      future: _routineFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading routine"));
        }

        final routine = teacherProvider.teacher!.routine;
        final currentTime = DateTime.now();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi! ${teacherProvider.teacher!.name}",
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                "Today's classes",
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: routine.length,
                  itemBuilder: (ctx, index) {
                    final session = routine[index];
                    final startTime = session.startTime;
                    final endTime = session.endTime;

                    bool ended = currentTime.isAfter(endTime);
                    bool current =
                        currentTime.isAfter(startTime) &&
                        currentTime.isBefore(endTime);

                    return TeacherClassTile(
                      onShowAttendance: showAttendanceModal,
                      session: session,
                      ended: ended,
                      current: current,
                      index: index,
                      totalSesssions: routine.length,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
