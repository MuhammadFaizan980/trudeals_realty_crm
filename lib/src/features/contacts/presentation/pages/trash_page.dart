import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/pipeline_cubit.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  List<Contact>? _trash;
  String? _error;
  String? _restoringId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
    });
    final result = await getIt<ContactsRepository>().getTrash();
    if (!mounted) return;
    result.fold(
      ifLeft: (e) => setState(() => _error = e.message),
      ifRight: (list) => setState(() => _trash = list..sort((a, b) => (b.deletedAt ?? b.createdAt).compareTo(a.deletedAt ?? a.createdAt))),
    );
  }

  Future<void> _restore(Contact c) async {
    setState(() => _restoringId = c.id);
    final result = await getIt<ContactsRepository>().restoreContact(c.id);
    if (!mounted) return;
    setState(() => _restoringId = null);
    result.fold(
      ifLeft: (e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))),
      ifRight: (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.name} restored')));
        getIt<PipelineCubit>().refresh();
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 34.px, vertical: 20.px),
      children: [
        Container(
          padding: EdgeInsets.all(13.px),
          decoration: BoxDecoration(
            color: TruDealsColors.sageMist,
            borderRadius: BorderRadius.circular(8.px),
          ),
          child: Text(
            "Profiles are never permanently deleted. Deleted profiles live here with their full history, and only a Super User can restore them.",
            style: TextStyle(fontSize: 12.5.px, color: TruDealsColors.inkSoft),
          ),
        ),
        SizedBox(height: 16.px),
        if (_error != null)
          Container(
            padding: EdgeInsets.all(16.px),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.px), border: Border.all(color: TruDealsColors.line)),
            child: Column(
              children: [
                Text(_error!, style: TextStyle(color: TruDealsColors.inkSoft)),
                SizedBox(height: 10.px),
                OutlinedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          )
        else if (_trash == null)
          const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
        else if (_trash!.isEmpty)
          Container(
            padding: EdgeInsets.all(30.px),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.px), border: Border.all(color: TruDealsColors.line)),
            child: Text('Trash is empty.', style: TextStyle(color: TruDealsColors.inkSoft)),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.px),
              border: Border.all(color: TruDealsColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: 700.px),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1),
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
                        _headerCell('Deleted'),
                        _headerCell('Deleted By'),
                        _headerCell(''),
                      ],
                    ),
                    ..._trash!.map((c) => TableRow(
                          children: [
                            _dataCell(Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            _dataCell(Text(c.propertyAddress?.isNotEmpty == true ? c.propertyAddress! : '—', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            _dataCell(Text(c.deletedAt != null ? DateFormat('MMM d, h:mm a').format(c.deletedAt!) : '—', style: const TextStyle(fontFamily: 'DM Mono'))),
                            _dataCell(Text(c.deletedBy != null ? getIt<PipelineCubit>().state.userName(c.deletedBy) : '—')),
                            _dataCell(
                              _restoringId == c.id
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : TextButton(onPressed: () => _restore(c), child: const Text('Restore contact')),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _headerCell(String label) {
    return Padding(
      padding: EdgeInsets.all(16.px),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5.px,
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
