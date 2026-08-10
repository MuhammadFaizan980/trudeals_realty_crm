import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:trudeals_realty_crm/src/features/calendar/domain/entities/callback_event.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardState {
  final DashboardStats? stats;
  final List<CallbackEvent> schedule;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    this.stats,
    this.schedule = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardState &&
          runtimeType == other.runtimeType &&
          stats == other.stats &&
          listEquals(schedule, other.schedule) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      stats.hashCode ^ schedule.hashCode ^ isLoading.hashCode ^ errorMessage.hashCode;

  DashboardState copyWith({
    DashboardStats? stats,
    List<CallbackEvent>? schedule,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      schedule: schedule ?? this.schedule,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
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
      final results = await Future.wait([
        _repository.getStats(),
        _repository.getTodaySchedule(),
      ]).timeout(const Duration(seconds: 5));

      final statsResult = results[0];
      final scheduleResult = results[1];

      DashboardStats? stats;
      List<CallbackEvent> schedule = [];
      String? error;

      (statsResult as dynamic).fold(
        ifLeft: (e) {
          debugPrint('DashboardCubit: statsResult Error: ${e.message}');
          error = (e as dynamic).message;
        },
        ifRight: (s) {
          debugPrint('DashboardCubit: statsResult Success');
          stats = s;
        },
      );
      
      (scheduleResult as dynamic).fold(
        ifLeft: (e) {
          debugPrint('DashboardCubit: scheduleResult Error: ${e.message}');
          error ??= (e as dynamic).message;
        },
        ifRight: (s) {
          debugPrint('DashboardCubit: scheduleResult Success: ${s.length} items');
          schedule = s;
        },
      );

      emit(state.copyWith(
        isLoading: false,
        stats: stats,
        schedule: schedule,
        errorMessage: error,
      ));
    } catch (e, stack) {
      debugPrint('DashboardCubit: loadDashboard Exception: $e\n$stack');
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to load dashboard: $e'));
    }
  }
}
