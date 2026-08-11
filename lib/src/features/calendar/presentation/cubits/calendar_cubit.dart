import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trudeals_realty_crm/src/features/calendar/domain/entities/callback_event.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Distinguishes "not passed" from "explicitly passed null" in [CalendarState.copyWith]
/// so error fields can be cleared on purpose without every unrelated call
/// having to repeat the other two slices' current error back at themselves.
const _unset = Object();

class CalendarState {
  final List<CallbackEvent> events;
  final DateTime selectedDate;
  final bool isLoading;
  final String? errorMessage;

  final DateTime visibleMonth;
  final List<CallbackEvent> monthEvents;
  final bool isMonthLoading;
  final String? monthErrorMessage;

  final DateTime visibleWeekStart;
  final List<CallbackEvent> weekEvents;
  final bool isWeekLoading;
  final String? weekErrorMessage;

  const CalendarState({
    this.events = const [],
    required this.selectedDate,
    this.isLoading = false,
    this.errorMessage,
    required this.visibleMonth,
    this.monthEvents = const [],
    this.isMonthLoading = false,
    this.monthErrorMessage,
    required this.visibleWeekStart,
    this.weekEvents = const [],
    this.isWeekLoading = false,
    this.weekErrorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarState &&
          runtimeType == other.runtimeType &&
          listEquals(events, other.events) &&
          selectedDate == other.selectedDate &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          visibleMonth == other.visibleMonth &&
          listEquals(monthEvents, other.monthEvents) &&
          isMonthLoading == other.isMonthLoading &&
          monthErrorMessage == other.monthErrorMessage &&
          visibleWeekStart == other.visibleWeekStart &&
          listEquals(weekEvents, other.weekEvents) &&
          isWeekLoading == other.isWeekLoading &&
          weekErrorMessage == other.weekErrorMessage;

  @override
  int get hashCode =>
      events.hashCode ^
      selectedDate.hashCode ^
      isLoading.hashCode ^
      errorMessage.hashCode ^
      visibleMonth.hashCode ^
      monthEvents.hashCode ^
      isMonthLoading.hashCode ^
      monthErrorMessage.hashCode ^
      visibleWeekStart.hashCode ^
      weekEvents.hashCode ^
      isWeekLoading.hashCode ^
      weekErrorMessage.hashCode;

  /// Every calendar day (normalized to midnight) within [visibleMonth] that
  /// has at least one event — used to decide which day cells get a dot.
  Set<DateTime> get daysWithEvents => _daysOf(monthEvents);

  /// Same idea as [daysWithEvents] but scoped to [visibleWeekStart]'s week.
  Set<DateTime> get daysWithEventsInWeek => _daysOf(weekEvents);

  static Set<DateTime> _daysOf(List<CallbackEvent> events) =>
      events.map((e) => DateTime(e.scheduledAt.year, e.scheduledAt.month, e.scheduledAt.day)).toSet();

  CalendarState copyWith({
    List<CallbackEvent>? events,
    DateTime? selectedDate,
    bool? isLoading,
    Object? errorMessage = _unset,
    DateTime? visibleMonth,
    List<CallbackEvent>? monthEvents,
    bool? isMonthLoading,
    Object? monthErrorMessage = _unset,
    DateTime? visibleWeekStart,
    List<CallbackEvent>? weekEvents,
    bool? isWeekLoading,
    Object? weekErrorMessage = _unset,
  }) {
    return CalendarState(
      events: events ?? this.events,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset) ? this.errorMessage : errorMessage as String?,
      visibleMonth: visibleMonth ?? this.visibleMonth,
      monthEvents: monthEvents ?? this.monthEvents,
      isMonthLoading: isMonthLoading ?? this.isMonthLoading,
      monthErrorMessage: identical(monthErrorMessage, _unset) ? this.monthErrorMessage : monthErrorMessage as String?,
      visibleWeekStart: visibleWeekStart ?? this.visibleWeekStart,
      weekEvents: weekEvents ?? this.weekEvents,
      isWeekLoading: isWeekLoading ?? this.isWeekLoading,
      weekErrorMessage: identical(weekErrorMessage, _unset) ? this.weekErrorMessage : weekErrorMessage as String?,
    );
  }
}

DateTime _startOfWeek(DateTime date) {
  final dateOnly = DateTime(date.year, date.month, date.day);
  // Sunday-first week: Sunday(7) % 7 == 0, Monday(1) % 7 == 1, … Saturday(6) % 7 == 6.
  return dateOnly.subtract(Duration(days: dateOnly.weekday % 7));
}

class CalendarCubit extends Cubit<CalendarState> {
  final DashboardRepository _repository;

  CalendarCubit(this._repository)
      : super(CalendarState(
          selectedDate: DateTime.now(),
          visibleMonth: DateTime(DateTime.now().year, DateTime.now().month),
          visibleWeekStart: _startOfWeek(DateTime.now()),
        ));

  Future<void> loadEvents(DateTime date) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, selectedDate: date));
    final result = await _repository.getSchedule(from: date, to: date);
    result.fold(
      ifLeft: (error) => emit(state.copyWith(isLoading: false, errorMessage: error.message)),
      ifRight: (events) => emit(state.copyWith(isLoading: false, errorMessage: null, events: events)),
    );
  }

  /// Loads every event within the month containing [month] — powers the dot
  /// markers on the month grid. Kept independent of [loadEvents]/[events] so
  /// switching months never clobbers whichever single day is being viewed.
  Future<void> loadMonth(DateTime month) async {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    emit(state.copyWith(isMonthLoading: true, monthErrorMessage: null, visibleMonth: firstOfMonth));
    final result = await _repository.getSchedule(from: firstOfMonth, to: lastOfMonth);
    result.fold(
      ifLeft: (error) => emit(state.copyWith(isMonthLoading: false, monthErrorMessage: error.message)),
      ifRight: (events) => emit(state.copyWith(isMonthLoading: false, monthErrorMessage: null, monthEvents: events)),
    );
  }

  /// Loads every event within the Sunday-start week containing [anyDayInWeek]
  /// — powers the dot markers on the week strip. Independent of the month
  /// and single-day slices for the same reason [loadMonth] is: a week can
  /// straddle two months, so it can't just reuse [monthEvents].
  Future<void> loadWeek(DateTime anyDayInWeek) async {
    final weekStart = _startOfWeek(anyDayInWeek);
    final weekEnd = weekStart.add(const Duration(days: 6));
    emit(state.copyWith(isWeekLoading: true, weekErrorMessage: null, visibleWeekStart: weekStart));
    final result = await _repository.getSchedule(from: weekStart, to: weekEnd);
    result.fold(
      ifLeft: (error) => emit(state.copyWith(isWeekLoading: false, weekErrorMessage: error.message)),
      ifRight: (events) => emit(state.copyWith(isWeekLoading: false, weekErrorMessage: null, weekEvents: events)),
    );
  }
}
