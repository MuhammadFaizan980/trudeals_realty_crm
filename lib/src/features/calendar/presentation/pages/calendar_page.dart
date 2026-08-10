import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/features/calendar/presentation/cubits/calendar_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/widgets/contact_drawer.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CalendarCubit>()..loadEvents(DateTime.now()),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatelessWidget {
  const _CalendarView();

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
