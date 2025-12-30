import 'package:flutter/material.dart';

import '../../../flutter_gantt.dart';
import '../controller_extension.dart';

/// A widget that displays ISO week numbers in a row for the Gantt chart calendar grid.
class WeekNumbersRow extends StatelessWidget {
  /// The Gantt controller that provides week data.
  final GanttController controller;

  /// Creates a [WeekNumbersRow] widget.
  const WeekNumbersRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final weeks = controller.weeks.entries.toList();
    return Row(
      children: List.generate(weeks.length, (i) {
        final week = weeks[i];
        return Expanded(
          flex: week.value,
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'W${week.key}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Container(
                width: 1,
                color:
                    (i < weeks.length - 1) ? Colors.grey : Colors.transparent,
                height: 10,
              ),
            ],
          ),
        );
      }),
    );
  }
}
