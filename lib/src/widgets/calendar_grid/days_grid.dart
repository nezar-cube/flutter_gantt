import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../flutter_gantt.dart';
import '../../utils/datetime.dart';
import '../controller_extension.dart';

/// A widget that displays day cells in a grid for the Gantt chart calendar grid.
class DaysGrid extends StatelessWidget {
  /// The Gantt controller that provides day data.
  final GanttController controller;

  /// The list of holidays to highlight in the calendar.
  final List<GantDateHoliday>? holidays;

  final GanttDisplayMode displayMode;

  /// Creates a [DaysGrid] widget.
  const DaysGrid({
    super.key,
    required this.controller,
    this.holidays,
    required this.displayMode,
  });

  /// Gets the background color for a specific date based on theme and holidays.
  ///
  /// Returns:
  /// - [GanttTheme.holidayColor] for holidays
  /// - [GanttTheme.weekendColor] for weekends
  /// - [Colors.transparent] for normal weekdays
  Color getDayColor(GanttTheme theme, DateTime date) {
    if ((holidays ?? []).map((e) => e.date).contains(date)) {
      return theme.holidayColor;
    }
    if (date.isWeekend) {
      return theme.weekendColor;
    }
    return Colors.transparent;
  }

  /// Gets the holiday name for a specific date, if any.
  ///
  /// Returns the holiday name if the date matches a holiday in [holidays],
  /// otherwise returns null.
  String? getDayHoliday(DateTime date) =>
      (holidays ?? [])
          .where((e) => e.date.isAtSameMomentAs(date))
          .firstOrNull
          ?.holiday;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      children: List.generate(controller.days.length, (i) {
        final day = controller.days[i];
        final holiday = getDayHoliday(day);
        final theme = context.watch<GanttTheme>();
        final child =
            displayMode == GanttDisplayMode.day
                ? DayView(day: day, theme: theme)
                : SizedBox.shrink();
        return Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: getDayColor(theme, day),
                  height: double.infinity,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          holiday != null
                              ? Tooltip(message: holiday, child: child)
                              : child,
                          if (holiday != null)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: double.infinity,
                width: 1,
                color:
                    controller.dateToHighlight(day)
                        ? theme.defaultCellColor
                        : Colors.grey,
              ),
            ],
          ),
        );
      }),
    ),
  );
}

class DayView extends StatelessWidget {
  const DayView({super.key, required this.day, required this.theme});

  final DateTime day;
  final GanttTheme theme;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,

      color: day.isToday ? theme.todayBackgroundColor : null,
    ),
    child: Text(
      '${day.day}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: day.isToday ? theme.todayTextColor : null,
        fontWeight: day.isToday ? FontWeight.bold : FontWeight.normal,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    ),
  );
}
