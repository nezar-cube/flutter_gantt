import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../flutter_gantt.dart';

/// Displays the list of activity names on the left side of the Gantt chart.
///
/// This widget shows activity titles, optional icons, and action buttons in a
/// scrollable list that synchronizes with the [ActivitiesGrid].
class ActivitiesList extends StatelessWidget {
  /// The list of [GanttActivity] items to display.
  ///
  /// Can contain hierarchical activities with parent-child relationships.
  final List<GanttActivity> activities;

  /// Optional [ScrollController] to synchronize scrolling with the grid view.
  final ScrollController? controller;

  /// Creates an [ActivitiesList] widget.
  ///
  /// [activities] must not be null and should contain at least one activity.
  /// [showIsoWeek] enables the ISO week-number row (default: `false`).
  const ActivitiesList({
    super.key,
    required this.activities,
    this.controller,
    this.showIsoWeek = false,
  });

  /// Whether to show the ISO week number row.
  ///
  /// If `true`, a row displaying ISO-8601 week numbers is shown
  /// between the month headers and the day cells.
  final bool showIsoWeek;

  /// Recursively builds widgets for activities and their children.
  ///
  /// [activities] - The list of activities to build widgets for
  /// [theme] - The current [GanttTheme] for styling
  /// [nested] - The current nesting level (used for indentation)
  List<Widget> getItems(
    BuildContext context,
    List<GanttActivity> activities,
    GanttTheme theme, {
    int nested = 0,
  }) {
    // Detect if text contains Arabic characters
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    
    return List.generate(
      activities.length,
      (index) => Padding(
        padding: EdgeInsets.only(
          top: theme.rowPadding + (nested == 0 ? theme.rowsGroupPadding : 0),
          left: 8.0 * (nested + 1),
          right: isArabic ? 12.0 : 8.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: theme.cellHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (activities[index].iconTitle != null)
                    Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: activities[index].iconTitle!,
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: isArabic ? 8.0 : 0,
                        left: isArabic ? 0 : 4.0,
                      ),
                      child:
                          activities[index].listTitleWidget ??
                          activities[index].titleWidget ??
                          Tooltip(
                            message: activities[index].tooltip ?? '',
                            child: Text(
                              activities[index].listTitle ??
                                  activities[index].title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: isArabic ? TextAlign.right : TextAlign.left,
                              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                            ),
                          ),
                    ),
                  ),
                  if (activities[index].actions?.isNotEmpty == true)
                    Row(
                      children:
                          activities[index].actions!.map((e) {
                            final child = IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: e.onTap,
                              icon: Icon(e.icon, size: theme.cellHeight * 0.8),
                            );
                            return e.tooltip != null
                                ? Tooltip(message: e.tooltip, child: child)
                                : child;
                          }).toList(),
                    ),
                ],
              ),
            ),
            if (activities[index].children?.isNotEmpty == true)
              ...getItems(context, activities[index].children!, theme, nested: nested + 1),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Consumer<GanttTheme>(
    builder:
        (context, theme, child) => Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Colors.black87,
                width: 1,
              ),
            ),
          ),
          child: Builder(
            builder: (context) {
              final locale = Localizations.localeOf(context);
              final isArabic = locale.languageCode == 'ar';
              return Padding(
                padding: EdgeInsets.only(
                  top: theme.headerHeight + (showIsoWeek ? 10 : 0),
                  right: isArabic ? 4.0 : 0,
                ),
                child: ListView(
                  controller: controller,
                  children: getItems(context, activities, theme),
                ),
              );
            },
          ),
        ),
  );
}
