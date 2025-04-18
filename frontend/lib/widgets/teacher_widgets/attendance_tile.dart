import 'package:flutter/material.dart';

class AttendanceTile extends StatelessWidget {
  const AttendanceTile({
    super.key,
    required this.student,
    required this.isPresent,
    required this.onChanged,
  });

  final Map<String, dynamic> student;
  final bool? isPresent;
  final void Function(bool?) onChanged;

  @override
  Widget build(BuildContext context) {
    final name = student['name'];
    final roll = student['roll'].toString();
    final displayRoll = roll.substring(roll.length - 3);
    final isInClass = student['is_in_class'];

    return Opacity(
      // opacity: isInClass ? 1.0 : 0.5,
      opacity: 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    displayRoll,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(width: 16),
                  Text("$name", style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),

              Row(
                children: [
                  ChoiceChip(
                    label: const Text('P'),
                    selected: isPresent == true,
                    selectedColor: Colors.green,
                    showCheckmark: false,
                    shape: const CircleBorder(),
                    onSelected:
                        !isInClass
                            ? (_) {
                              onChanged(true);
                            }
                            : null,
                    labelStyle: TextStyle(
                      color: isPresent == true ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('A'),
                    selected: isPresent == false,
                    selectedColor: Colors.red,
                    showCheckmark: false,
                    shape: const CircleBorder(),
                    onSelected:
                        !isInClass
                            ? (_) {
                              onChanged(false);
                            }
                            : null,
                    labelStyle: TextStyle(
                      color: isPresent == false ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
