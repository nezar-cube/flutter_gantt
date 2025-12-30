import 'package:flutter/material.dart';

import '../../../flutter_gantt.dart';
import '../controller_extension.dart';

/// A widget that displays month headers in a row for the Gantt chart calendar grid.
class MonthHeadersRow extends StatelessWidget {
  /// The Gantt controller that provides month data.
  final GanttController controller;

  /// Optional callback to customize month text formatting.
  final MonthToText? monthToText;

  /// Creates a [MonthHeadersRow] widget.
  const MonthHeadersRow({
    super.key,
    required this.controller,
    this.monthToText,
  });

  @override
  Widget build(BuildContext context) {
    final months = controller.getMonths(context, monthToText).entries.toList();
    return Row(
      children: List.generate(months.length, (i) {
        final month = months[i];
        return Expanded(
          flex: month.value,
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    month.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Container(
                width: 1,
                color:
                    (i < months.length - 1) ? Colors.grey : Colors.transparent,
                height: 10,
              ),
            ],
          ),
        );
      }),
    );
  }
}
