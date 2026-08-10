import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trudeals_realty_crm/src/features/calendar/domain/entities/callback_event.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardState {
  final List<CallbackEvent> todaySchedule;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    this.todaySchedule = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardState &&
          runtimeType == other.runtimeType &&
          listEquals(todaySchedule, other.todaySchedule) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => todaySchedule.hashCode ^ isLoading.hashCode ^ errorMessage.hashCode;

  DashboardState copyWith({List<CallbackEvent>? todaySchedule, bool? isLoading, String? errorMessage}) {
    return DashboardState(
      todaySchedule: todaySchedule ?? this.todaySchedule,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit(this._repository) : super(const DashboardState());

  Future<void> loadDashboard() async {
    debugPrint('DashboardCubit: loadDashboard starting...');
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final today = DateTime.now();
      final result = await _repository.getSchedule(from: today, to: today);
      result.fold(
        ifLeft: (e) => emit(state.copyWith(isLoading: false, errorMessage: e.message)),
        ifRight: (events) => emit(state.copyWith(isLoading: false, todaySchedule: events)),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to load dashboard: $e'));
    }
  }
}
