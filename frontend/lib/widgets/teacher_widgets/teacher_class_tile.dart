import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/utility/push_notification_service.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:frontend/utility/geofencing.dart';
import 'package:http/http.dart' as http;

class TeacherClassTile extends StatefulWidget {
  const TeacherClassTile({
    super.key,
    required this.index,
    required this.totalSesssions,
    required this.session,
    required this.current,
    required this.ended,
    required this.onShowAttendance,
  });

  final int index;
  final int totalSesssions;
  final Session session;
  final bool current;
  final bool ended;
  final void Function(
    String section,
    String subject,
    void Function() onAttendanceGiven,
  )
  onShowAttendance;

  @override
  State<TeacherClassTile> createState() => _TeacherClassTileState();
}

class _TeacherClassTileState extends State<TeacherClassTile> {
  late bool classStarted;
  late bool attendanceGiven;
  late bool classCancelled;

  Future<void> startClass() async {
    var url = Uri.parse(
      "https://smart-attendance-app-hackathon.onrender.com/api/routine/${widget.session.id}",
    );

    var res = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': 'classStarted'}),
    );

    if (res.statusCode == 200) {
      setState(() {
        classStarted = true;
      });
    }
  }

  Future<void> cancelClass() async {
    var url = Uri.parse(
      "https://smart-attendance-app-hackathon.onrender.com/api/routine/${widget.session.id}",
    );

    var res = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': 'cancelled'}),
    );

    if (res.statusCode == 200) {
      setState(() {
        classCancelled = true;
      });
    }
  }

  Future<void> toggleAttendanceGiven() async {
    var url = Uri.parse(
      "https://smart-attendance-app-hackathon.onrender.com/api/routine/${widget.session.id}",
    );

    var res = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': 'attendanceGiven'}),
    );

    if (res.statusCode == 200) {
      setState(() {
        attendanceGiven = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    classStarted =
        widget.session.status.contains('classStarted') ? true : false;
    attendanceGiven =
        widget.session.status.contains('attendanceGiven') ? true : false;
    classCancelled = widget.session.status.contains('cancelled') ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TimelineTile(
      alignment: TimelineAlign.manual,
      lineXY: 0.05,
      isFirst: widget.index == 0,
      isLast: widget.index == widget.totalSesssions - 1,
      indicatorStyle: IndicatorStyle(
        width: widget.current ? 18.0 : 15.0,
        color:
            widget.current
                ? const Color.fromARGB(255, 74, 222, 143)
                : (widget.ended
                    ? Colors.grey
                    : const Color.fromARGB(255, 183, 235, 230)),
      ),
      beforeLineStyle: LineStyle(
        color: widget.ended ? Colors.grey : Colors.teal,
      ),
      endChild: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              classCancelled
                  ? const Color.fromARGB(255, 255, 187, 194)
                  : (widget.ended ? Colors.grey.shade300 : Colors.white),
          border: Border.all(
            color: widget.current ? Colors.teal : Colors.grey,
            width: widget.current ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 150,
                  child: Text(
                    "${widget.session.startTimeString} - ${widget.session.endTimeString}",
                    style: TextStyle(
                      fontWeight:
                          widget.current ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.session.subject,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          widget.current ? FontWeight.bold : FontWeight.normal,
                      color: widget.ended ? Colors.grey : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "dept: ${widget.session.department}",
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              "class: ${widget.session.section}",
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),

            if (!classCancelled) ...[
              //start class button
              if (widget.current && !classStarted)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    backgroundColor: const Color.fromARGB(255, 34, 119, 42),
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: startClass,
                  child: const Text("Start class"),
                ),

              const SizedBox(height: 16),
              //give attendance button
              if ((widget.current && classStarted) || widget.ended)
                ElevatedButton.icon(
                  icon: const Icon(Icons.people),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed:
                      widget.ended || attendanceGiven
                          ? null
                          : () {
                            widget.onShowAttendance(
                              widget.session.section,
                              widget.session.subject,
                              toggleAttendanceGiven,
                            );
                          },
                  label: const Text("Give attendance"),
                ),
              if (!widget.ended && !widget.current)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    backgroundColor: theme.colorScheme.error.withAlpha(180),
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: cancelClass,
                  label: const Text("Cancel class"),
                  icon: const Icon(Icons.cancel),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
