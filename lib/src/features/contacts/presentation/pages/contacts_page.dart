import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/pipeline_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/widgets/contact_drawer.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PipelineCubit>()..loadContacts(),
      child: const _ContactsView(),
    );
  }
}

class _ContactsView extends StatelessWidget {
  const _ContactsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PipelineCubit, PipelineState>(
      builder: (context, state) {
        if (state.isLoading) return const Center(child: CircularProgressIndicator());

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.px),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search leads...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(vertical: 9.px, horizontal: 13.px),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.px),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.px),
                    decoration: BoxDecoration(
                      border: Border.all(color: TruDealsColors.line),
                      borderRadius: BorderRadius.circular(8.px),
                      color: Colors.white,
                    ),
                    child: DropdownButton<String>(
                      value: null,
                      underline: const SizedBox.shrink(),
                      hint: const Text('All stages'),
                      style: TextStyle(fontSize: 13.px, color: TruDealsColors.ink),
                      items: const [
                        DropdownMenuItem(value: 'new', child: Text('New Lead')),
                        DropdownMenuItem(value: 'contacted', child: Text('Contacted')),
                      ],
                      onChanged: (v) {},
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.px),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.px),
                    border: Border.all(color: TruDealsColors.line),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: 900.px),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(3),
                            2: FlexColumnWidth(1.5),
                            3: FlexColumnWidth(1.2),
                            4: FlexColumnWidth(1.5),
                            5: FlexColumnWidth(1.2),
                            6: FlexColumnWidth(1.2),
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Color(0xFFFBFAF7),
                                border: Border(bottom: BorderSide(color: TruDealsColors.line)),
                              ),
                              children: [
                                _headerCell('Name'),
                                _headerCell('Property'),
                                _headerCell('Stage'),
                                _headerCell('Priority'),
                                _headerCell('Owner'),
                                _headerCell('Est. Price'),
                                _headerCell('Follow-up'),
                              ],
                            ),
                            ...state.contacts.map((c) => TableRow(
                              children: [
                                InkWell(
                                  onTap: () => _showContactDrawer(context, c.id),
                                  child: _dataCell(Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                ),
                                _dataCell(Text(c.propertyAddress ?? '—')),
                                _dataCell(_StageChip(label: c.stage)),
                                _dataCell(_PriorityTag(priority: c.priority)),
                                _dataCell(Text(c.assignedTo ?? '—')),
                                _dataCell(Text('\$${(c.dealValue / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontFamily: 'DM Mono'))),
                                _dataCell(Text(c.followUp != null ? DateFormat('MM/dd').format(c.followUp!) : '—', style: const TextStyle(fontFamily: 'DM Mono'))),
                              ],
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.px),
            ],
          ),
        );
      },
    );
  }

  void _showContactDrawer(BuildContext context, String contactId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContactDrawer(contactId: contactId),
    );
  }

  Widget _headerCell(String label) {
    return Padding(
      padding: EdgeInsets.all(16.px),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11.px,
          letterSpacing: 0.09,
          fontWeight: FontWeight.w700,
          color: TruDealsColors.inkSoft,
        ),
      ),
    );
  }

  Widget _dataCell(Widget child) {
    return Padding(
      padding: EdgeInsets.all(16.px),
      child: child,
    );
  }
}

class _StageChip extends StatelessWidget {
  final String label;
  const _StageChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.px, vertical: 4.px),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEEE8),
        borderRadius: BorderRadius.circular(99.px),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 11.px, fontWeight: FontWeight.w600, color: TruDealsColors.charcoalSoft),
      ),
    );
  }
}

class _PriorityTag extends StatelessWidget {
  final Priority priority;
  const _PriorityTag({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      Priority.high => TruDealsColors.redBg,
      Priority.med => TruDealsColors.amberBg,
      _ => TruDealsColors.sageMist,
    };
    final textColor = switch (priority) {
      Priority.high => TruDealsColors.red,
      Priority.med => TruDealsColors.amber,
      _ => TruDealsColors.sageDeep,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.px, vertical: 3.px),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99.px)),
      child: Text(priority.name.toUpperCase(), style: TextStyle(fontSize: 10.px, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}
