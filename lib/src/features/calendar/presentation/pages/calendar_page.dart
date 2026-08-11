import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import 'package:trudeals_realty_crm/src/features/calendar/presentation/cubits/calendar_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/widgets/contact_drawer.dart';

enum _ViewMode { month, week, day }

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final CalendarCubit _cubit = getIt<CalendarCubit>();
  _ViewMode _mode = _ViewMode.month;

  @override
  void initState() {
    super.initState();
    _cubit.loadMonth(DateTime.now());
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Column(
        children: [
          _ViewModeToggle(
            mode: _mode,
            onChanged: (mode) {
              setState(() => _mode = mode);
              switch (mode) {
                case _ViewMode.month:
                  _cubit.loadMonth(_cubit.state.visibleMonth);
                case _ViewMode.week:
                  _cubit.loadWeek(_cubit.state.visibleWeekStart);
                case _ViewMode.day:
                  _cubit.loadEvents(_cubit.state.selectedDate);
              }
            },
          ),
          Expanded(
            child: switch (_mode) {
              _ViewMode.month => _MonthView(onDayTap: _openDay),
              _ViewMode.week => _WeekView(onDayTap: _openDay),
              _ViewMode.day => const _DayView(),
            },
          ),
        ],
      ),
    );
  }

  void _openDay(DateTime date) {
    setState(() => _mode = _ViewMode.day);
    _cubit.loadEvents(date);
  }
}

class _ViewModeToggle extends StatelessWidget {
  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChanged;
  const _ViewModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.px, 10.px, 16.px, 4.px),
      color: const Color(0xFFFBFAF7),
      alignment: Alignment.center,
      child: SegmentedButton<_ViewMode>(
        segments: const [
          ButtonSegment(value: _ViewMode.month, label: Text('Month')),
          ButtonSegment(value: _ViewMode.week, label: Text('Week')),
          ButtonSegment(value: _ViewMode.day, label: Text('Day')),
        ],
        selected: {mode},
        onSelectionChanged: (selection) => onChanged(selection.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: TruDealsColors.sageDeep,
          selectedForegroundColor: Colors.white,
          foregroundColor: TruDealsColors.ink,
        ),
      ),
    );
  }
}

/// Month grid, dots-for-events landing view — mirrors the Google Calendar
/// app's monthly view. Tapping a day switches to the Day view for that date.
class _MonthView extends StatelessWidget {
  final ValueChanged<DateTime> onDayTap;
  const _MonthView({required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _MonthHeader(),
        const _WeekdayLabels(),
        Expanded(
          child: BlocBuilder<CalendarCubit, CalendarState>(
            builder: (context, state) {
              if (state.isMonthLoading && state.monthEvents.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.monthErrorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.monthErrorMessage!, textAlign: TextAlign.center),
                      SizedBox(height: 12.px),
                      OutlinedButton(
                        onPressed: () => context.read<CalendarCubit>().loadMonth(state.visibleMonth),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return _MonthGrid(state: state, onDayTap: onDayTap);
            },
          ),
        ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        final isCurrentMonth = state.visibleMonth.year == DateTime.now().year && state.visibleMonth.month == DateTime.now().month;
        return Container(
          padding: EdgeInsets.all(16.px),
          color: const Color(0xFFFBFAF7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => context
                    .read<CalendarCubit>()
                    .loadMonth(DateTime(state.visibleMonth.year, state.visibleMonth.month - 1)),
              ),
              Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(state.visibleMonth),
                    style: TextStyle(fontSize: 17.px, fontWeight: FontWeight.bold),
                  ),
                  if (!isCurrentMonth)
                    TextButton(
                      onPressed: () => context.read<CalendarCubit>().loadMonth(DateTime.now()),
                      style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      child: const Text('Jump to today', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => context
                    .read<CalendarCubit>()
                    .loadMonth(DateTime(state.visibleMonth.year, state.visibleMonth.month + 1)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.px, vertical: 6.px),
      child: Row(
        children: _labels
            .map((l) => Expanded(
                  child: Center(
                    child: Text(l, style: TextStyle(fontSize: 12.px, fontWeight: FontWeight.w700, color: TruDealsColors.inkSoft)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final CalendarState state;
  final ValueChanged<DateTime> onDayTap;
  const _MonthGrid({required this.state, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final month = state.visibleMonth;
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // Sunday-first grid: Sunday(7) % 7 == 0, Monday(1) % 7 == 1, … Saturday(6) % 7 == 6.
    final leadingBlanks = firstOfMonth.weekday % 7;
    final totalCells = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;
    final gridStart = firstOfMonth.subtract(Duration(days: leadingBlanks));
    final today = DateTime.now();
    final daysWithEvents = state.daysWithEvents;

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 8.px, vertical: 4.px),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.85),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final date = gridStart.add(Duration(days: index));
        final inCurrentMonth = date.month == month.month;
        final isToday = _isSameDay(date, today);
        final hasEvents = daysWithEvents.contains(DateTime(date.year, date.month, date.day));

        return InkWell(
          onTap: () => onDayTap(date),
          child: Padding(
            padding: EdgeInsets.all(2.px),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30.px,
                  height: 30.px,
                  alignment: Alignment.center,
                  decoration: isToday ? const BoxDecoration(color: TruDealsColors.sageDeep, shape: BoxShape.circle) : null,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 13.5.px,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday
                          ? Colors.white
                          : inCurrentMonth
                              ? TruDealsColors.ink
                              : TruDealsColors.inkSoft.withAlpha(140),
                    ),
                  ),
                ),
                SizedBox(height: 3.px),
                SizedBox(
                  height: 6.px,
                  width: 6.px,
                  child: hasEvents
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: isToday ? TruDealsColors.sageDeep : TruDealsColors.sage,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Sunday-start week strip — same dots-for-events idea as the month grid,
/// scoped to one week. Tapping a day switches to the Day view for that date.
class _WeekView extends StatelessWidget {
  final ValueChanged<DateTime> onDayTap;
  const _WeekView({required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _WeekHeader(),
        Expanded(
          child: BlocBuilder<CalendarCubit, CalendarState>(
            builder: (context, state) {
              if (state.isWeekLoading && state.weekEvents.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.weekErrorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.weekErrorMessage!, textAlign: TextAlign.center),
                      SizedBox(height: 12.px),
                      OutlinedButton(
                        onPressed: () => context.read<CalendarCubit>().loadWeek(state.visibleWeekStart),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return _WeekStrip(state: state, onDayTap: onDayTap);
            },
          ),
        ),
      ],
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        final weekStart = state.visibleWeekStart;
        final weekEnd = weekStart.add(const Duration(days: 6));
        final isCurrentWeek = _isSameDay(weekStart, DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7)));
        final label = weekStart.month == weekEnd.month
            ? '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('d, yyyy').format(weekEnd)}'
            : '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('MMM d, yyyy').format(weekEnd)}';
        return Container(
          padding: EdgeInsets.all(16.px),
          color: const Color(0xFFFBFAF7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => context.read<CalendarCubit>().loadWeek(weekStart.subtract(const Duration(days: 7))),
              ),
              Column(
                children: [
                  Text(label, style: TextStyle(fontSize: 15.5.px, fontWeight: FontWeight.bold)),
                  if (!isCurrentWeek)
                    TextButton(
                      onPressed: () => context.read<CalendarCubit>().loadWeek(DateTime.now()),
                      style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      child: const Text('Jump to this week', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => context.read<CalendarCubit>().loadWeek(weekStart.add(const Duration(days: 7))),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final CalendarState state;
  final ValueChanged<DateTime> onDayTap;
  const _WeekStrip({required this.state, required this.onDayTap});

  static const _labels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysWithEvents = state.daysWithEventsInWeek;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.px, vertical: 16.px),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(7, (i) {
          final date = state.visibleWeekStart.add(Duration(days: i));
          final isToday = _isSameDay(date, today);
          final hasEvents = daysWithEvents.contains(DateTime(date.year, date.month, date.day));

          return Expanded(
            child: InkWell(
              onTap: () => onDayTap(date),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.px),
                child: Column(
                  children: [
                    Text(
                      _labels[i],
                      style: TextStyle(fontSize: 10.5.px, fontWeight: FontWeight.w700, color: TruDealsColors.inkSoft),
                    ),
                    SizedBox(height: 8.px),
                    Container(
                      width: 34.px,
                      height: 34.px,
                      alignment: Alignment.center,
                      decoration: isToday ? const BoxDecoration(color: TruDealsColors.sageDeep, shape: BoxShape.circle) : null,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 14.5.px,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday ? Colors.white : TruDealsColors.ink,
                        ),
                      ),
                    ),
                    SizedBox(height: 5.px),
                    SizedBox(
                      height: 6.px,
                      width: 6.px,
                      child: hasEvents
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                color: isToday ? TruDealsColors.sageDeep : TruDealsColors.sage,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// The day-level agenda. Header shows the selected day's weekday + date,
/// body is a vertical list of that day's events (call backs / follow-ups).
class _DayView extends StatelessWidget {
  const _DayView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _DateSelector(),
        Expanded(
          child: BlocBuilder<CalendarCubit, CalendarState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.errorMessage!, textAlign: TextAlign.center),
                      SizedBox(height: 12.px),
                      OutlinedButton(
                        onPressed: () => context.read<CalendarCubit>().loadEvents(state.selectedDate),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (state.events.isEmpty) {
                return const Center(child: Text('No call backs or follow-ups scheduled for this day'));
              }
              return ListView.builder(
                padding: EdgeInsets.all(16.px),
                itemCount: state.events.length,
                itemBuilder: (context, index) {
                  final event = state.events[index];
                  return Card(
                    child: ListTile(
                      onTap: () => showContactDrawer(context, event.contactId),
                      title: Text(event.contactName),
                      subtitle: Text(event.note ?? 'Call back'),
                      trailing: Text(DateFormat('h:mm a').format(event.scheduledAt)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        final isToday = DateUtils.isSameDay(state.selectedDate, DateTime.now());
        return Container(
          padding: EdgeInsets.all(16.px),
          color: const Color(0xFFFBFAF7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => context.read<CalendarCubit>().loadEvents(state.selectedDate.subtract(const Duration(days: 1))),
              ),
              Column(
                children: [
                  Text(
                    DateFormat('EEEE, MMM d').format(state.selectedDate),
                    style: TextStyle(fontSize: 17.px, fontWeight: FontWeight.bold),
                  ),
                  if (!isToday)
                    TextButton(
                      onPressed: () => context.read<CalendarCubit>().loadEvents(DateTime.now()),
                      style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      child: const Text('Jump to today', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => context.read<CalendarCubit>().loadEvents(state.selectedDate.add(const Duration(days: 1))),
              ),
            ],
          ),
        );
      },
    );
  }
}
