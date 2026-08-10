import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trudeals_realty_crm/src/features/calendar/domain/entities/callback_event.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/domain/repositories/dashboard_repository.dart';

class CalendarState {
  final List<CallbackEvent> events;
  final DateTime selectedDate;
  final bool isLoading;
  final String? errorMessage;

  const CalendarState({
    this.events = const [],
    required this.selectedDate,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarState &&
          runtimeType == other.runtimeType &&
          listEquals(events, other.events) &&
          selectedDate == other.selectedDate &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      events.hashCode ^ selectedDate.hashCode ^ isLoading.hashCode ^ errorMessage.hashCode;

  CalendarState copyWith({
    List<CallbackEvent>? events,
    DateTime? selectedDate,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CalendarState(
      events: events ?? this.events,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CalendarCubit extends Cubit<CalendarState> {
  final DashboardRepository _repository;

  CalendarCubit(this._repository) : super(CalendarState(selectedDate: DateTime.now()));

  Future<void> loadEvents(DateTime date) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, selectedDate: date));
    final result = await _repository.getTodaySchedule();
    result.fold(
      ifLeft: (error) => emit(state.copyWith(isLoading: false, errorMessage: error.message)),
      ifRight: (events) => emit(state.copyWith(isLoading: false, events: events)),
    );
  }
}
