import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:provider/provider.dart';

import '../../flutter_gantt.dart';
import 'activities_grid.dart';
import 'activities_list.dart';
import 'calendar_grid/calendar_grid.dart';
import 'controller_extension.dart';

/// A function that converts a [DateTime] representing a month
/// into its textual representation, using the given [BuildContext].
///
/// The [BuildContext] can be used to access localization,
/// theme data, or other inherited widgets.
///
/// The returned string is typically a localized or human-readable
/// name of the month (e.g. "January", "Jan", "Gennaio").
///
/// Example:
/// ```dart
/// String monthName(BuildContext context, DateTime date) {
///   return MaterialLocalizations.of(context).formatMonthYear(date);
/// }
/// ```
typedef MonthToText = String Function(BuildContext context, DateTime date);

/// A customizable Gantt chart widget for Flutter.
///
/// Displays activities in a timeline view with configurable appearance and behavior.
/// The chart consists of three main components:
/// 1. ActivitiesList - Shows activity names on the left
/// 2. CalendarGrid - Shows date headers at the top
/// 3. ActivitiesGrid - Shows activity durations on the right
class Gantt extends StatefulWidget {
  /// The initial start date to display.
  final DateTime? startDate;

  /// The list of activities to display (mutually exclusive with [activitiesAsync]).
  final List<GanttActivity>? activities;

  /// Async function to load activities (mutually exclusive with [activities]).
  ///
  /// This function is called when the date range changes to fetch new activities.
  final Future<List<GanttActivity>> Function(
    DateTime startDate,
    DateTime endDate,
    List<GanttActivity> activities,
  )?
  activitiesAsync;

  /// The list of holidays to highlight (mutually exclusive with [holidaysAsync]).
  final List<GantDateHoliday>? holidays;

  /// Async function to load holidays (mutually exclusive with [holidays]).
  final Future<List<GantDateHoliday>> Function(
    DateTime startDate,
    DateTime endDate,
    List<GantDateHoliday> holidays,
  )?
  holidaysAsync;

  /// The theme to use for the Gantt chart.
  final GanttTheme? theme;

  /// The controller for managing Gantt chart state.
  final GanttController? controller;

  /// Callback when an activity's dates changes.
  final GanttActivityOnChangedEvent? onActivityChanged;

  /// Enable draggable cell.
  final bool enableDraggable;

  /// When set to true, this parameter enables the independent movement of a parent task within the Gantt chart, regardless of the fixed date boundaries of its child tasks.
  final bool allowParentIndependentDateMovement;

  /// The list of dates to highlight
  final List<DateTime>? highlightedDates;

  /// The flex ratio for the activities list column (default: 1).
  final int activitiesListFlex;

  /// The flex ratio for the grid area column (default: 4).
  final int gridAreaFlex;

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

  /// Whether the activities list can be collapsed/expanded.
  ///
  /// If `true`, a toggle button will be shown to collapse or expand
  /// the activities list on the left side of the Gantt chart.
  /// Defaults to `false`.
  final bool enableCollapsibleActivitiesList;

  /// The list of weekday numbers that should be treated as weekend days.
  ///
  /// Weekday numbers: 1 = Monday, 2 = Tuesday, ..., 7 = Sunday.
  /// Defaults to [6, 7] (Saturday and Sunday).
  /// These days will be highlighted with [GanttTheme.weekendColor].
  final List<int> weekendDays;

  /// Whether to force the text direction to LTR.
  ///
  /// If `true`, the text direction will be forced to LTR regardless of the system locale.
  /// Defaults to `false`.
  final bool forceLTR;

  /// Creates a [Gantt] chart widget.
  ///
  /// Throws an [AssertionError] if:
  /// - Neither [startDate] nor [controller] is provided
  /// - Both [activities] and [activitiesAsync] are provided or both are null
  /// - Both [holidays] and [holidaysAsync] are provided
  /// [showIsoWeek] enables the ISO week-number row (default: `false`).
  const Gantt({
    super.key,
    this.startDate,
    this.theme,
    this.activities,
    this.activitiesAsync,
    this.holidays,
    this.holidaysAsync,
    this.controller,
    this.onActivityChanged,
    this.highlightedDates,
    this.enableDraggable = true,
    this.allowParentIndependentDateMovement = false,
    this.activitiesListFlex = 1,
    this.gridAreaFlex = 4,
    this.showIsoWeek = false,
    this.monthToText,
    this.displayMode = GanttDisplayMode.day,
    this.enableCollapsibleActivitiesList = false,
    this.weekendDays = const [6, 7], // Default: Saturday and Sunday
    this.forceLTR = false,
  }) : assert(
         (startDate != null || controller != null) &&
             ((activities == null) != (activitiesAsync == null)) &&
             (holidays == null || holidaysAsync == null),
       );

  @override
  State<Gantt> createState() => _GanttState();
}

class _GanttState extends State<Gantt> {
  late GanttTheme theme;
  late GanttController controller;
  Offset? _lastPosition;
  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _listController;
  late ScrollController _gridColumnsController;
  bool _loading = false;
  
  // Static variable to persist collapsed state across widget rebuilds
  static bool _isActivitiesListCollapsedState = false;
  
  bool get _isActivitiesListCollapsed => _isActivitiesListCollapsedState;
  
  void _setIsActivitiesListCollapsed(bool value) {
    setState(() {
      _isActivitiesListCollapsedState = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _listController = _linkedControllers.addAndGet();
    _gridColumnsController = _linkedControllers.addAndGet();
    theme = widget.theme ?? GanttTheme();
    controller =
        widget.controller ?? GanttController(startDate: widget.startDate);
    controller.theme = theme;
    controller.addFetchListener(_getAsync);
    if (widget.onActivityChanged != null) {
      controller.addOnActivityChangedListener(widget.onActivityChanged!);
    }
    if (widget.holidays != null) {
      controller.setHolidays(widget.holidays!, notify: false);
    }
    if (widget.activities != null) {
      controller.setActivities(widget.activities!, notify: false);
    } else {
      controller.fetch();
    }
    if (widget.highlightedDates != null) {
      controller.setHighlightedDates(widget.highlightedDates!, notify: false);
    }
    controller.enableDraggable = widget.enableDraggable;
    controller.allowParentIndependentDateMovement =
        widget.allowParentIndependentDateMovement;
  }

  @override
  void dispose() {
    controller.removeFetchListener(_getAsync);
    if (widget.onActivityChanged != null) {
      controller.removeOnActivityChangedListener(widget.onActivityChanged!);
    }
    if (widget.controller == null) {
      controller.dispose();
    }
    _listController.dispose();
    _gridColumnsController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) =>
      _lastPosition = details.localPosition;

  void _handlePanUpdate(
    DragUpdateDetails details,
    double maxWidth,
    BuildContext context,
  ) {
    final dayWidth = maxWidth / controller.internalDaysViews;

    // Increase threshold for month mode to slow down scrolling
    final thresholdFactor = switch (widget.displayMode) {
      GanttDisplayMode.month => 20.0,
      GanttDisplayMode.week => 1.0,
      GanttDisplayMode.day => 1.0,
    };
    final threshold = dayWidth * thresholdFactor;
    
    final dx = (details.localPosition.dx - _lastPosition!.dx);
    if (_lastPosition != null && dx.abs() > threshold) {
      // Check text direction to handle RTL correctly
      // Try Directionality first, fallback to locale check
      final textDirection = Directionality.of(context);
      final locale = Localizations.localeOf(context);
      final isRTL =
          textDirection == TextDirection.rtl ||
          locale.languageCode == 'ar' ||
          locale.languageCode == 'he' ||
          locale.languageCode == 'fa' ||
          locale.languageCode == 'ur';

      // In RTL, swap next/prev to match user expectations
      // LTR: negative dx (left) → next, positive dx (right) → prev
      // RTL: negative dx (left) → prev, positive dx (right) → next
      if (isRTL && !widget.forceLTR) {
        // In RTL, invert the logic
        if (dx.isNegative) {
          controller.prev(fetchData: false); // Drag left → earlier dates
        } else {
          controller.next(fetchData: false); // Drag right → later dates
        }
      } else {
        // LTR behavior (original)
        if (dx.isNegative) {
          controller.next(fetchData: false);
        } else {
          controller.prev(fetchData: false);
        }
      }
      _lastPosition = details.localPosition;
    }
  }

  void _handlePanEnd(DragEndDetails details) => _reset();

  void _handlePanCancel() => _reset();

  void _reset() {
    _lastPosition = null;
    controller.fetch();
  }

  Future<void> _getAsync() async {
    if (widget.activitiesAsync != null || widget.holidaysAsync != null) {
      var activities = <GanttActivity>[];
      var holidays = <GantDateHoliday>[];
      setState(() {
        _loading = true;
      });
      if (widget.activitiesAsync != null) {
        activities = await widget.activitiesAsync!(
          controller.startDate,
          controller.endDate,
          controller.activities,
        );
        controller.setActivities(activities, notify: false);
      }
      if (widget.holidaysAsync != null) {
        holidays = await widget.holidaysAsync!(
          controller.startDate,
          controller.endDate,
          controller.holidays,
        );
        controller.setHolidays(holidays, notify: false);
      }
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<GanttTheme>.value(value: theme),
      ChangeNotifierProvider<GanttController>.value(value: controller),
    ],
    builder: (context, child) {
      final c = context.watch<GanttController>();
      return Container(
        color: theme.backgroundColor,
        child: Column(
          children: [
            SizedBox(
              height: 4,
              child: _loading ? LinearProgressIndicator() : Container(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final textDirection = Directionality.of(context);
                  final isRTL = textDirection == TextDirection.rtl;

                  final activitiesListWidth =
                      _isActivitiesListCollapsed
                          ? 0.0
                          : (totalWidth * widget.activitiesListFlex) /
                              (widget.activitiesListFlex + widget.gridAreaFlex);

                  // Calculate button position based on text direction
                  double? buttonLeft;
                  double? buttonRight;

                  if (_isActivitiesListCollapsed) {
                    // When collapsed, position at the edge
                    if (isRTL) {
                      buttonRight = 4.0;
                    } else {
                      buttonLeft = 4.0;
                    }
                  } else {
                    // When expanded, position at the boundary between list and grid
                    if (isRTL) {
                      // In RTL, Row reverses children, so activities list is visually on the right
                      // Button should be at the boundary, positioned from the right edge
                      // The boundary is at activitiesListWidth from the right
                      buttonRight = activitiesListWidth - 16;
                    } else {
                      // In LTR, activities list is on the left side
                      // Button should be at the right edge of the list (boundary)
                      buttonLeft = activitiesListWidth - 16;
                    }
                  }

                  return LayoutBuilder(
                    builder:
                        (context, stackConstraints) => Stack(
                          children: [
                            Row(
                              textDirection: textDirection,
                              children: [
                                if (widget.enableCollapsibleActivitiesList)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    width: _isActivitiesListCollapsed
                                        ? 0.0
                                        : activitiesListWidth,
                                    child: _isActivitiesListCollapsed
                                        ? const SizedBox.shrink()
                                        : ActivitiesList(
                                            activities: c.activities,
                                            controller: _listController,
                                            showIsoWeek: widget.showIsoWeek,
                                          ),
                                  )
                                else
                                  Expanded(
                                    flex: widget.activitiesListFlex,
                                    child: ActivitiesList(
                                      activities: c.activities,
                                      controller: _listController,
                                      showIsoWeek: widget.showIsoWeek,
                                    ),
                                  ),
                                Expanded(
                                  flex: widget.gridAreaFlex,
                                  child: LayoutBuilder(
                                    builder: (context, gridConstraints) {
                                      controller.gridWidth =
                                          gridConstraints.maxWidth;
                                      return GestureDetector(
                                        onPanStart: _handlePanStart,
                                        onPanUpdate:
                                            (details) => _handlePanUpdate(
                                              details,
                                              gridConstraints.maxWidth,
                                              context,
                                            ),
                                        onPanEnd: _handlePanEnd,
                                        onPanCancel: _handlePanCancel,
                                        child: Stack(
                                          children: [
                                            CalendarGrid(
                                              holidays: c.holidays,
                                              showIsoWeek: widget.showIsoWeek,
                                              monthToText: widget.monthToText,
                                              displayMode: widget.displayMode,
                                              weekendDays: widget.weekendDays,
                                            ),
                                            ActivitiesGrid(
                                              activities: c.activities,
                                              controller:
                                                  _gridColumnsController,
                                              showIsoWeek: widget.showIsoWeek,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (widget.enableCollapsibleActivitiesList)
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                left: buttonLeft,
                                right: buttonRight,
                                top: (stackConstraints.maxHeight - 30) / 2,
                                child: _CollapseExpandButton(
                                  isCollapsed: _isActivitiesListCollapsed,
                                  isRTL: isRTL,
                                  onToggle: () {
                                    _setIsActivitiesListCollapsed(
                                        !_isActivitiesListCollapsed);
                                  },
                                ),
                              ),
                          ],
                        ),
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

/// A button widget for collapsing/expanding the activities list in the Gantt chart.
class _CollapseExpandButton extends StatelessWidget {
  const _CollapseExpandButton({
    required this.isCollapsed,
    required this.isRTL,
    required this.onToggle,
  });

  final bool isCollapsed;
  final bool isRTL;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(4),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => RotationTransition(
            turns: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        child: Icon(
          isCollapsed
              ? (isRTL ? Icons.chevron_left : Icons.chevron_right)
              : (isRTL ? Icons.chevron_right : Icons.chevron_left),
          key: ValueKey(isCollapsed),
          size: 18,
          color: Colors.white,
        ),
      ),
      onPressed: onToggle,
      tooltip:
          isCollapsed ? 'Expand activities list' : 'Collapse activities list',
      padding: const EdgeInsets.all(3),
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
    ),
  );
}
