import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/entities/user.dart';
import 'package:trudeals_realty_crm/src/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/pipeline_cubit.dart';

const _sourceOptions = ['Postcard', 'Website', 'Referral', 'Sign call', 'Social media', 'Other'];
const _planOptions = {
  'fsbo': '\$995 FSBO',
  'full': '0.5% Full-Service',
  'premium': '1% Premium',
  'dual05': 'Dual with 0.5%',
  'dual1': 'Dual with 1%',
  'undecided': 'Undecided',
};

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class AddContactPage extends StatefulWidget {
  /// Pass an existing contact to edit it instead of creating a new one.
  final Contact? existing;
  const AddContactPage({super.key, this.existing});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _phoneController = TextEditingController(text: widget.existing?.phone ?? '');
  late final _emailController = TextEditingController(text: widget.existing?.email ?? '');
  late final _addressController = TextEditingController(text: widget.existing?.propertyAddress ?? '');
  late final _valueController = TextEditingController(text: widget.existing?.dealValue.toStringAsFixed(0) ?? '');

  late String _source = widget.existing?.source ?? _sourceOptions.first;
  late String _plan = _planOptions.containsKey(widget.existing?.plan) ? widget.existing!.plan : 'undecided';
  late Priority _priority = widget.existing?.priority ?? Priority.med;
  String? _stageKey;
  String? _assignedTo;
  DateTime? _followUp;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _followUp = widget.existing?.followUp;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AddContactPage is reached via Navigator.push, which sits outside the
    // BlocProvider<PipelineCubit> scope (see the architecture note in
    // pipeline_cubit.dart) — a StreamBuilder straight off the singleton's
    // own stream keeps this reactive without needing that ancestry.
    final pipelineCubit = getIt<PipelineCubit>();
    return StreamBuilder<PipelineState>(
      stream: pipelineCubit.stream,
      initialData: pipelineCubit.state,
      builder: (context, snapshot) => _buildForm(context, snapshot.data ?? pipelineCubit.state),
    );
  }

  Widget _buildForm(BuildContext context, PipelineState pipeline) {
    final effectiveStageKey = _stageKey ?? (pipeline.stages.isNotEmpty ? pipeline.stages.first.key : null);
    final effectiveAssignedTo = _assignedTo ?? (pipeline.users.isNotEmpty ? pipeline.users.first.id : null);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit contact' : 'New contact')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.px),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name*'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              SizedBox(height: 14.px),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                  return digits.length < 7 ? 'Enter a valid phone number' : null;
                },
              ),
              SizedBox(height: 14.px),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return _emailRegex.hasMatch(v.trim()) ? null : 'Enter a valid email address';
                },
              ),
              SizedBox(height: 14.px),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Property address'),
              ),
              SizedBox(height: 14.px),
              DropdownButtonFormField<String>(
                initialValue: _source,
                decoration: const InputDecoration(labelText: 'Lead source'),
                items: _sourceOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _source = v ?? _source),
              ),
              SizedBox(height: 14.px),
              DropdownButtonFormField<String>(
                initialValue: _plan,
                decoration: const InputDecoration(labelText: 'Plan'),
                items: _planOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _plan = v ?? _plan),
              ),
              SizedBox(height: 14.px),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Est. sale price (\$)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v.trim());
                  if (n == null) return 'Enter a valid number';
                  if (n < 0) return 'Must be zero or more';
                  return null;
                },
              ),
              SizedBox(height: 14.px),
              DropdownButtonFormField<Priority>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _priority = v ?? _priority),
              ),
              if (!_isEdit) ...[
                SizedBox(height: 14.px),
                DropdownButtonFormField<String>(
                  initialValue: effectiveStageKey,
                  decoration: const InputDecoration(labelText: 'Pipeline stage'),
                  items: pipeline.stages.map((s) => DropdownMenuItem(value: s.key, child: Text(s.label))).toList(),
                  onChanged: (v) => setState(() => _stageKey = v),
                ),
                SizedBox(height: 14.px),
                DropdownButtonFormField<String>(
                  initialValue: effectiveAssignedTo,
                  decoration: const InputDecoration(labelText: 'Assigned to'),
                  items: pipeline.users.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.name} — ${u.dept}'))).toList(),
                  onChanged: (v) => setState(() => _assignedTo = v),
                ),
              ] else
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.px),
                  child: Text(
                    'Use "Transfer contact" and "Advance stage" on the profile to change owner or stage.',
                    style: TextStyle(fontSize: 12.px, color: Colors.grey[600]),
                  ),
                ),
              SizedBox(height: 14.px),
              InkWell(
                onTap: _pickFollowUp,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Next follow-up'),
                  child: Text(_followUp != null ? DateFormat('MMM d, yyyy').format(_followUp!) : 'No date set'),
                ),
              ),
              SizedBox(height: 28.px),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50.px)),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Save changes' : 'Save contact'),
              ),
              if (_isEdit && (getIt<AuthCubit>().state as Authenticated?)?.user.role == UserRole.superAdmin) ...[
                SizedBox(height: 10.px),
                OutlinedButton(
                  onPressed: _saving ? null : _moveToTrash,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, minimumSize: Size(double.infinity, 46.px)),
                  child: const Text('Move to Trash'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFollowUp() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUp ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _followUp = picked);
  }

  /// Only sends fields that actually changed from the loaded contact. The
  /// real API refuses to let non-super seats blank out a field — sending
  /// the whole form unconditionally (including fields the user never
  /// touched) risks tripping that guard on a field that was already empty
  /// for an unrelated reason, and rejecting an edit the user never intended.
  Map<String, dynamic> _buildEditPatch() {
    final existing = widget.existing!;
    final patch = <String, dynamic>{};

    void put(String key, dynamic newValue, dynamic oldValue) {
      if (newValue != oldValue) patch[key] = newValue;
    }

    put('name', _nameController.text.trim(), existing.name);
    put('phone', _phoneController.text.trim(), existing.phone ?? '');
    put('email', _emailController.text.trim(), existing.email ?? '');
    put('propertyAddress', _addressController.text.trim(), existing.propertyAddress ?? '');
    put('source', _source, existing.source ?? _sourceOptions.first);
    put('plan', _plan, existing.plan);
    put('dealValue', double.tryParse(_valueController.text.trim()) ?? 0, existing.dealValue);
    put('priority', _priority.name, existing.priority.name);

    final followUpStr = _followUp?.toIso8601String().split('T').first;
    final existingFollowUpStr = existing.followUp?.toIso8601String().split('T').first;
    if (followUpStr != existingFollowUpStr) patch['followUp'] = followUpStr;

    return patch;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isEdit) {
      final patch = _buildEditPatch();
      if (patch.isEmpty) {
        Navigator.pop(context, false);
        return;
      }
    }

    setState(() => _saving = true);

    final repo = getIt<ContactsRepository>();
    final result = _isEdit
        ? await repo.updateContact(widget.existing!.id, _buildEditPatch())
        : await repo.createContact(Contact(
            id: '',
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            propertyAddress: _addressController.text.trim(),
            source: _source,
            plan: _plan,
            stage: _stageKey ?? getIt<PipelineCubit>().state.stages.firstOrNull?.key ?? 'new',
            dealValue: double.tryParse(_valueController.text.trim()) ?? 0,
            priority: _priority,
            assignedTo: _assignedTo ?? getIt<PipelineCubit>().state.users.firstOrNull?.id,
            followUp: _followUp,
            createdAt: DateTime.now(),
          ));

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      ifLeft: (e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))),
      ifRight: (_) => Navigator.pop(context, true),
    );
  }

  Future<void> _moveToTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: Text('${widget.existing!.name} will move to Trash. Only a Super Admin can restore it — the record and its history are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Move to Trash', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final result = await getIt<ContactsRepository>().deleteContact(widget.existing!.id);
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      ifLeft: (e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))),
      ifRight: (_) => Navigator.pop(context, true),
    );
  }
}
