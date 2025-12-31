import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../flutter_gantt.dart';
import 'days_grid.dart';
import 'month_headers_row.dart';
import 'week_numbers_row.dart';

/// Displays the calendar grid portion of the Gantt chart.
///
/// Shows:
/// - Month headers
/// - (Optional) ISO week numbers
/// - Day cells with weekend/holiday highlighting
///
/// This grid appears above the activities grid to provide date context.
class CalendarGrid extends StatelessWidget {
  /// The list of holidays to highlight in the calendar.
  ///
  /// Holidays will be displayed with special background color and tooltips.
  final List<GantDateHoliday>? holidays;

  /// Whether to show the ISO week number row.
  ///
  /// If `true`, a row displaying ISO-8601 week numbers is shown
  /// between the month headers and the day cells.
  final bool showIsoWeek;

  /// A callback used to convert a [DateTime] value into a textual
  /// representation of its month, using the provided [BuildContext].
  ///
  /// If provided, this function overrides the default month-to-text
  /// conversion logic.
  /// If `null`, a fallback or built-in formatter may be used instead.
  final MonthToText? monthToText;

  /// The display mode for the Gantt chart.
  ///
  /// Determines the granularity of the timeline view:
  /// - [GanttDisplayMode.day]: Shows individual days (default)
  /// - [GanttDisplayMode.week]: Shows weeks
  /// - [GanttDisplayMode.month]: Shows months
  final GanttDisplayMode displayMode;

  /// The list of weekday numbers that should be treated as weekend days.
  ///
  /// Weekday numbers: 1 = Monday, 2 = Tuesday, ..., 7 = Sunday.
  /// Defaults to [6, 7] (Saturday and Sunday).
  final List<int> weekendDays;

  /// Creates a [CalendarGrid] widget.
  ///
  /// [holidays] is optional and can be null when no holiday highlighting is needed.
  /// [showIsoWeek] enables the ISO week-number row (default: `false`).
  const CalendarGrid({
    super.key,
    this.holidays,
    this.showIsoWeek = false,
    this.monthToText,
    this.displayMode = GanttDisplayMode.day,
    this.weekendDays = const [6, 7],
  });

  @override
  Widget build(BuildContext context) => Consumer<GanttController>(
    builder:
        (context, c, child) {
          // Use displayMode from controller instead of widget parameter
          // so it updates when the controller's displayMode changes
          final currentDisplayMode = c.displayMode;
          return Column(
          children: [
            // Month headers row
            MonthHeadersRow(controller: c, monthToText: monthToText),
            // Week numbers row
            if (showIsoWeek) WeekNumbersRow(controller: c),
            // Days grid
            DaysGrid(
              controller: c,
              holidays: holidays,
              displayMode: currentDisplayMode,
              weekendDays: weekendDays,
            ),
          ],
        );
        },
  );
}
