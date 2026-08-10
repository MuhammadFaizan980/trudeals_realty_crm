import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/pipeline_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/stage.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/widgets/contact_drawer.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _stageFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PipelineCubit, PipelineState>(
      builder: (context, state) {
        if (state.isLoading && state.contacts.isEmpty && state.stages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null && state.contacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.errorMessage!, style: TextStyle(color: TruDealsColors.inkSoft)),
                SizedBox(height: 12.px),
                OutlinedButton(onPressed: () => context.read<PipelineCubit>().refresh(), child: const Text('Retry')),
              ],
            ),
          );
        }

        var list = state.contacts.where((c) => !c.deleted).toList()..sort((a, b) => a.name.compareTo(b.name));
        if (_query.trim().isNotEmpty) {
          final q = _query.trim().toLowerCase();
          list = list.where((c) {
            final haystack = [c.name, c.propertyAddress, c.email, c.phone, c.source, state.userName(c.assignedTo)]
                .where((s) => s != null)
                .join(' ')
                .toLowerCase();
            return haystack.contains(q);
          }).toList();
        }
        if (_stageFilter != null && _stageFilter!.isNotEmpty) {
          list = list.where((c) => c.stage == _stageFilter).toList();
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.px),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search leads...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(vertical: 9.px, horizontal: 13.px),
                      ),
                      onChanged: (v) => setState(() => _query = v),
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
                    child: DropdownButton<String?>(
                      value: _stageFilter,
                      underline: const SizedBox.shrink(),
                      hint: const Text('All stages'),
                      style: TextStyle(fontSize: 13.px, color: TruDealsColors.ink),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All stages')),
                        ...state.stages.map((s) => DropdownMenuItem<String?>(value: s.key, child: Text(s.label))),
                      ],
                      onChanged: (v) => setState(() => _stageFilter = v),
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
                  child: list.isEmpty
                      ? Center(
                          child: Text(
                            state.contacts.isEmpty ? 'No contacts yet.' : 'No contacts match.',
                            style: TextStyle(color: TruDealsColors.inkSoft),
                          ),
                        )
                      : SingleChildScrollView(
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
                                  ...list.map((c) => TableRow(
                                        children: [
                                          InkWell(
                                            onTap: () => showContactDrawer(context, c.id),
                                            child: _dataCell(_ellipsized(c.name, bold: true)),
                                          ),
                                          _dataCell(_ellipsized(c.propertyAddress?.isNotEmpty == true ? c.propertyAddress! : '—')),
                                          _dataCell(_StageChip(label: _stageLabel(state.stages, c.stage))),
                                          _dataCell(_PriorityTag(priority: c.priority)),
                                          _dataCell(_ellipsized(state.userName(c.assignedTo))),
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

  String _stageLabel(List<Stage> stages, String key) {
    for (final s in stages) {
      if (s.key == key) return s.label;
    }
    return key;
  }

  Widget _ellipsized(String text, {bool bold = false}) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
