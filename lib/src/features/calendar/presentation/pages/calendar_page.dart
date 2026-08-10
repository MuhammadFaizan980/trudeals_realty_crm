import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/features/calendar/presentation/cubits/calendar_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/pages/contact_detail_page.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CalendarCubit>()..loadEvents(DateTime.now()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Schedule'),
          backgroundColor: Colors.blueGrey[50],
        ),
        body: const _CalendarView(),
      ),
    );
  }
}

class _CalendarView extends StatelessWidget {
  const _CalendarView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DateSelector(),
        Expanded(
          child: BlocBuilder<CalendarCubit, CalendarState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.events.isEmpty) {
                return const Center(child: Text('No events scheduled for this day'));
              }
              return ListView.builder(
                padding: EdgeInsets.all(16.px),
                itemCount: state.events.length,
                itemBuilder: (context, index) {
                  final event = state.events[index];
                  return Card(
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContactDetailPage(contactId: event.contactId),
                          ),
                        );
                      },
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
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(16.px),
          color: Colors.blueGrey[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final newDate = state.selectedDate.subtract(const Duration(days: 1));
                  context.read<CalendarCubit>().loadEvents(newDate);
                },
              ),
              Text(
                DateFormat('EEEE, MMM d').format(state.selectedDate),
                style: TextStyle(fontSize: 18.px, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final newDate = state.selectedDate.add(const Duration(days: 1));
                  context.read<CalendarCubit>().loadEvents(newDate);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
