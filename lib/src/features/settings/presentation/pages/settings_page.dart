import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/stage.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/entities/user.dart';
import 'package:trudeals_realty_crm/src/features/settings/domain/repositories/settings_repository.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/pipeline_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<Stage> _stages = [];
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final repo = getIt<SettingsRepository>();
    final results = await Future.wait([repo.getStages(), repo.getUsers()]);

    String? error;
    results[0].fold(
      ifLeft: (e) => error = e.message,
      ifRight: (list) => _stages = (list as List<Stage>)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
    results[1].fold(ifLeft: (e) => error ??= e.message, ifRight: (list) => _users = list as List<User>);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = error;
    });
  }

  int _contactCountInStage(String key) => getIt<PipelineCubit>().state.contacts.where((c) => !c.deleted && c.stage == key).length;

  Future<void> _addStage() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const _StageEditorDialog(),
    );
    if (created == true) {
      _load();
      getIt<PipelineCubit>().refresh();
    }
  }

  Future<void> _reorder(int index, int delta) async {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _stages.length) return;
    final reordered = [..._stages];
    final moved = reordered.removeAt(index);
    reordered.insert(newIndex, moved);
    setState(() => _stages = reordered);
    final error = await _reorderStages(reordered.map((s) => s.key).toList());
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      _load();
    } else {
      getIt<PipelineCubit>().refresh();
    }
  }

  Future<String?> _reorderStages(List<String> order) async {
    final result = await getIt<SettingsRepository>().reorderStages(order);
    String? error;
    result.fold(ifLeft: (e) => error = e.message, ifRight: (_) {});
    return error;
  }

  Future<void> _removeStage(Stage stage) async {
    final inUse = _contactCountInStage(stage.key);
    if (inUse > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Can\'t remove "${stage.label}" — $inUse profile(s) are in it. Move them first.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove stage?'),
        content: Text('Remove stage "${stage.label}"? This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await getIt<SettingsRepository>().deleteStage(stage.key);
    result.fold(
      ifLeft: (e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))),
      ifRight: (_) {
        _load();
        getIt<PipelineCubit>().refresh();
      },
    );
  }

  Future<void> _manageSeat(User? user) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _SeatEditorDialog(existing: user),
    );
    if (saved == true) {
      _load();
      getIt<PipelineCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: TruDealsColors.inkSoft)),
            SizedBox(height: 12.px),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 34.px, vertical: 20.px),
      children: [
        _Panel(
          title: 'Pipeline stages & permissions',
          trailing: ElevatedButton(
            onPressed: _addStage,
            style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 11.px, vertical: 6.px)),
            child: const Text('+ Add stage'),
          ),
          child: Column(
            children: _stages.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return _StageRow(
                stage: s,
                isFirst: i == 0,
                isLast: i == _stages.length - 1,
                onMoveUp: () => _reorder(i, -1),
                onMoveDown: () => _reorder(i, 1),
                onRemove: () => _removeStage(s),
                onChanged: () {
                  _load();
                  getIt<PipelineCubit>().refresh();
                },
              );
            }).toList(),
          ),
        ),
        _Panel(
          title: 'Team seats',
          trailing: ElevatedButton(
            onPressed: () => _manageSeat(null),
            style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 11.px, vertical: 6.px)),
            child: const Text('+ New seat'),
          ),
          child: Column(
            children: [
              ..._users.map((u) => _UserRow(user: u, onManage: () => _manageSeat(u))),
              Padding(
                padding: EdgeInsets.all(20.px),
                child: Text(
                  'Each seat gets its own role, phone number, and signatures. Switch users in the sidebar to see each seat\'s view and permissions.',
                  style: TextStyle(fontSize: 11.px, color: TruDealsColors.inkSoft),
                ),
              ),
            ],
          ),
        ),
        _Panel(
          title: 'Integrations',
          child: Padding(
            padding: EdgeInsets.all(20.px),
            child: Text(
              'Twilio (SMS & voice) and Calendar sync (Google / Microsoft 365) connect via OAuth on the server side and aren\'t configured for this workspace yet.',
              style: TextStyle(fontSize: 13.5.px, color: TruDealsColors.inkSoft, height: 1.55),
            ),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  const _Panel({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 22.px),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.px),
        border: Border.all(color: TruDealsColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 15.px),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8.px,
              children: [
                Text(title, style: TextStyle(fontSize: 15.px, fontWeight: FontWeight.bold)),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1, color: TruDealsColors.line),
          child,
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  final Stage stage;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _StageRow({
    required this.stage,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 10.px),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0EFE9))),
      ),
      child: Row(
        children: [
          Column(
            children: [
              IconButton(onPressed: isFirst ? null : onMoveUp, icon: const Icon(Icons.arrow_upward, size: 14)),
              IconButton(onPressed: isLast ? null : onMoveDown, icon: const Icon(Icons.arrow_downward, size: 14)),
            ],
          ),
          SizedBox(width: 10.px),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stage.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Permissions: ${stage.roles.isEmpty ? "Super Admin only" : stage.roles.join(", ")}',
                    style: const TextStyle(fontSize: 12, color: TruDealsColors.inkSoft)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit stage',
            onPressed: () async {
              final saved = await showDialog<bool>(context: context, builder: (context) => _StageEditorDialog(existing: stage));
              if (saved == true) onChanged();
            },
          ),
          TextButton(onPressed: onRemove, child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _StageEditorDialog extends StatefulWidget {
  final Stage? existing;
  const _StageEditorDialog({this.existing});

  @override
  State<_StageEditorDialog> createState() => _StageEditorDialogState();
}

class _StageEditorDialogState extends State<_StageEditorDialog> {
  late final _labelController = TextEditingController(text: widget.existing?.label ?? '');
  late bool _sales = widget.existing?.roles.contains('sales') ?? true;
  late bool _support = widget.existing?.roles.contains('support') ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit stage' : 'New stage'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _labelController, decoration: const InputDecoration(labelText: 'Stage name')),
          SizedBox(height: 12.px),
          Text('Who besides Super Admin can move profiles in:', style: TextStyle(fontSize: 12.px, color: TruDealsColors.inkSoft)),
          CheckboxListTile(
            value: _sales,
            onChanged: (v) => setState(() => _sales = v ?? false),
            title: const Text('Sales Rep'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            value: _support,
            onChanged: (v) => setState(() => _support = v ?? false),
            title: const Text('Support Agent'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name the stage')));
      return;
    }
    setState(() => _saving = true);
    final roles = [if (_sales) 'sales', if (_support) 'support'];
    final stage = Stage(
      key: widget.existing?.key ?? '',
      label: label,
      roles: roles,
      sortOrder: widget.existing?.sortOrder ?? 0,
    );
    final result = await getIt<SettingsRepository>().saveStage(stage);
    if (!mounted) return;
    result.fold(
      ifLeft: (e) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      },
      ifRight: (_) => Navigator.pop(context, true),
    );
  }
}

class _UserRow extends StatelessWidget {
  final User user;
  final VoidCallback onManage;
  const _UserRow({required this.user, required this.onManage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 11.px),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0EFE9))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16.px,
            backgroundColor: TruDealsColors.sageMist,
            child: Text(
              user.name.trim().isNotEmpty ? user.name.trim()[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 13.px, fontWeight: FontWeight.bold, color: TruDealsColors.sageDeep),
            ),
          ),
          SizedBox(width: 12.px),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${user.dept} · ${user.phone?.isNotEmpty == true ? user.phone : "no seat number"}',
                    style: const TextStyle(fontSize: 12, color: TruDealsColors.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.px, vertical: 3.px),
            decoration: BoxDecoration(color: TruDealsColors.sageMist, borderRadius: BorderRadius.circular(99.px)),
            child: Text(user.role.label.toUpperCase(), style: TextStyle(fontSize: 10.5.px, fontWeight: FontWeight.w700, color: TruDealsColors.sageDeep)),
          ),
          SizedBox(width: 10.px),
          TextButton(onPressed: onManage, child: const Text('Manage seat', style: TextStyle(color: TruDealsColors.sageDeep))),
        ],
      ),
    );
  }
}

class _SeatEditorDialog extends StatefulWidget {
  final User? existing;
  const _SeatEditorDialog({this.existing});

  @override
  State<_SeatEditorDialog> createState() => _SeatEditorDialogState();
}

class _SeatEditorDialogState extends State<_SeatEditorDialog> {
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _deptController = TextEditingController(text: widget.existing?.dept ?? 'Sales');
  late final _phoneController = TextEditingController(text: widget.existing?.phone ?? '');
  late final _emailController = TextEditingController(text: widget.existing?.email ?? '');
  late UserRole _role = widget.existing?.role ?? UserRole.sales;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _deptController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Manage seat — ${widget.existing!.name}' : 'New seat'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full name')),
            SizedBox(height: 10.px),
            TextField(controller: _deptController, decoration: const InputDecoration(labelText: 'Department')),
            SizedBox(height: 10.px),
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Role'),
              items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            SizedBox(height: 10.px),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Dedicated phone')),
            SizedBox(height: 10.px),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email address')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save seat'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name the seat')));
      return;
    }
    setState(() => _saving = true);
    final user = User(
      id: widget.existing?.id ?? '',
      name: name,
      role: _role,
      dept: _deptController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      emailSig: widget.existing?.emailSig,
      smsSig: widget.existing?.smsSig,
    );
    final result = await getIt<SettingsRepository>().saveUser(user);
    if (!mounted) return;
    result.fold(
      ifLeft: (e) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      },
      ifRight: (_) => Navigator.pop(context, true),
    );
  }
}
