import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/features/automations/domain/entities/workflow.dart';
import 'package:trudeals_realty_crm/src/features/automations/domain/repositories/workflow_repository.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/pipeline_cubit.dart';
import 'package:trudeals_realty_crm/src/features/settings/domain/repositories/settings_repository.dart';

int _seq = 0;
String _tempId() => 'new-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

class WorkflowEditorPage extends StatefulWidget {
  final Workflow? workflow;
  const WorkflowEditorPage({super.key, this.workflow});

  @override
  State<WorkflowEditorPage> createState() => _WorkflowEditorPageState();
}

class _WorkflowEditorPageState extends State<WorkflowEditorPage> {
  late final _nameController = TextEditingController(text: widget.workflow?.name ?? '');
  late TriggerType _triggerType = widget.workflow?.triggerType ?? TriggerType.tag;
  late String _triggerValue = widget.workflow?.triggerValue ?? '';
  late List<WorkflowStep> _steps = List.of(widget.workflow?.steps ?? const []);

  List<Map<String, dynamic>> _emailTemplates = [];
  List<Map<String, dynamic>> _smsTemplates = [];
  bool _loadingTemplates = true;
  bool _saving = false;

  bool get _isEdit => widget.workflow != null;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final result = await getIt<SettingsRepository>().getTemplates();
    if (!mounted) return;
    result.fold(
      ifLeft: (_) {},
      ifRight: (map) => setState(() {
        _emailTemplates = (map['email'] ?? []).cast<Map<String, dynamic>>();
        _smsTemplates = (map['sms'] ?? []).cast<Map<String, dynamic>>();
      }),
    );
    setState(() => _loadingTemplates = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit workflow' : 'New workflow'),
        actions: [
          if (_isEdit)
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete workflow', onPressed: _saving ? null : _delete),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save workflow'),
          ),
        ],
      ),
      body: _loadingTemplates
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(24.px),
              children: [
                Text('Workflow name', style: TextStyle(fontSize: 14.px, fontWeight: FontWeight.bold)),
                SizedBox(height: 6.px),
                TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Seller Lead – Florida nurture')),
                SizedBox(height: 20.px),
                Text('Trigger (IF...)', style: TextStyle(fontSize: 14.px, fontWeight: FontWeight.bold)),
                SizedBox(height: 6.px),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TriggerType>(
                        initialValue: _triggerType,
                        decoration: const InputDecoration(labelText: 'Trigger'),
                        items: const [
                          DropdownMenuItem(value: TriggerType.tag, child: Text('Tag is added')),
                          DropdownMenuItem(value: TriggerType.form, child: Text('Form is submitted')),
                          DropdownMenuItem(value: TriggerType.stage, child: Text('Moved to stage')),
                          DropdownMenuItem(value: TriggerType.click, child: Text('Link is clicked')),
                        ],
                        onChanged: (v) => setState(() {
                          _triggerType = v ?? TriggerType.tag;
                          _triggerValue = '';
                        }),
                      ),
                    ),
                    SizedBox(width: 12.px),
                    Expanded(child: _triggerValueField()),
                  ],
                ),
                SizedBox(height: 24.px),
                Text('Steps (THEN...)', style: TextStyle(fontSize: 16.px, fontWeight: FontWeight.bold)),
                SizedBox(height: 10.px),
                if (_steps.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.px),
                    child: const Text('No steps yet — add the first one below.', style: TextStyle(color: Colors.grey)),
                  ),
                ..._steps.asMap().entries.map((e) => _StepCard(
                      key: ValueKey(e.value.id),
                      step: e.value,
                      isFirst: e.key == 0,
                      isLast: e.key == _steps.length - 1,
                      emailTemplates: _emailTemplates,
                      smsTemplates: _smsTemplates,
                      onChanged: (updated) => setState(() => _steps[e.key] = updated),
                      onRemove: () => setState(() => _steps.removeAt(e.key)),
                      onMoveUp: () => setState(() {
                        final s = _steps.removeAt(e.key);
                        _steps.insert(e.key - 1, s);
                      }),
                      onMoveDown: () => setState(() {
                        final s = _steps.removeAt(e.key);
                        _steps.insert(e.key + 1, s);
                      }),
                    )),
                SizedBox(height: 10.px),
                _AddStepControl(onAdd: (type) => setState(() => _steps.add(_defaultStepFor(type)))),
              ],
            ),
    );
  }

  Widget _triggerValueField() {
    switch (_triggerType) {
      case TriggerType.form:
        return DropdownButtonFormField<String>(
          initialValue: LeadType.values.any((l) => l.name == _triggerValue) ? _triggerValue : null,
          decoration: const InputDecoration(labelText: 'Lead type'),
          items: LeadType.values.map((l) => DropdownMenuItem(value: l.name, child: Text(l.name.toUpperCase()))).toList(),
          onChanged: (v) => setState(() => _triggerValue = v ?? ''),
        );
      case TriggerType.stage:
        final pipelineCubit = getIt<PipelineCubit>();
        return StreamBuilder<PipelineState>(
          stream: pipelineCubit.stream,
          initialData: pipelineCubit.state,
          builder: (context, snapshot) {
            final stages = (snapshot.data ?? pipelineCubit.state).stages;
            return DropdownButtonFormField<String>(
              initialValue: stages.any((s) => s.key == _triggerValue) ? _triggerValue : null,
              decoration: const InputDecoration(labelText: 'Stage'),
              items: stages.map((s) => DropdownMenuItem(value: s.key, child: Text(s.label))).toList(),
              onChanged: (v) => setState(() => _triggerValue = v ?? ''),
            );
          },
        );
      case TriggerType.click:
        return const InputDecorator(
          decoration: InputDecoration(labelText: 'Link'),
          child: Text('Any tracked link', style: TextStyle(color: Colors.grey)),
        );
      case TriggerType.tag:
        return TextFormField(
          initialValue: _triggerValue,
          decoration: const InputDecoration(labelText: 'Tag', hintText: 'seller-lead-florida'),
          onChanged: (v) => _triggerValue = v,
        );
    }
  }

  WorkflowStep _defaultStepFor(StepType type) {
    switch (type) {
      case StepType.email:
        return WorkflowStep(id: _tempId(), type: type, templateId: _emailTemplates.isNotEmpty ? _emailTemplates.first['_id']?.toString() : null);
      case StepType.sms:
        return WorkflowStep(id: _tempId(), type: type, templateId: _smsTemplates.isNotEmpty ? _smsTemplates.first['_id']?.toString() : null);
      case StepType.wait:
        return WorkflowStep(id: _tempId(), type: type, waitAmount: 10, waitUnit: 'min');
      case StepType.addTag:
      case StepType.removeTag:
        return WorkflowStep(id: _tempId(), type: type, value: '');
      case StepType.notify:
        return WorkflowStep(id: _tempId(), type: type, value: 'owner', notifyText: 'Automation alert: {{name}}');
      case StepType.ifCond:
        return WorkflowStep(id: _tempId(), type: type, cond: 'no_reply', ifFalse: 'stop', value: '');
      case StepType.stopAll:
        return WorkflowStep(id: _tempId(), type: type);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name the workflow')));
      return;
    }
    if (_triggerType == TriggerType.tag) {
      _triggerValue = _triggerValue.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    }

    setState(() => _saving = true);
    final workflow = Workflow(
      id: widget.workflow?.id ?? '',
      name: name,
      isActive: widget.workflow?.isActive ?? true,
      triggerType: _triggerType,
      triggerValue: _triggerValue,
      steps: _steps,
    );
    final repo = getIt<WorkflowRepository>();
    final result = _isEdit ? await repo.updateWorkflow(workflow) : await repo.createWorkflow(workflow);
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      ifLeft: (e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))),
      ifRight: (_) => Navigator.pop(context, true),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete workflow?'),
        content: Text('Delete "${widget.workflow!.name}"? Contacts currently enrolled will stop where they are.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final result = await getIt<WorkflowRepository>().deleteWorkflow(widget.workflow!.id);
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      ifLeft: (e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))),
      ifRight: (_) => Navigator.pop(context, true),
    );
  }
}

class _AddStepControl extends StatefulWidget {
  final void Function(StepType) onAdd;
  const _AddStepControl({required this.onAdd});

  @override
  State<_AddStepControl> createState() => _AddStepControlState();
}

class _AddStepControlState extends State<_AddStepControl> {
  StepType _type = StepType.email;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<StepType>(
            initialValue: _type,
            items: const [
              DropdownMenuItem(value: StepType.email, child: Text('Send email')),
              DropdownMenuItem(value: StepType.sms, child: Text('Send SMS')),
              DropdownMenuItem(value: StepType.wait, child: Text('Wait')),
              DropdownMenuItem(value: StepType.addTag, child: Text('Add tag')),
              DropdownMenuItem(value: StepType.removeTag, child: Text('Remove tag')),
              DropdownMenuItem(value: StepType.notify, child: Text('Notify team')),
              DropdownMenuItem(value: StepType.ifCond, child: Text('Condition (IF...)')),
              DropdownMenuItem(value: StepType.stopAll, child: Text('Stop other sequences')),
            ],
            onChanged: (v) => setState(() => _type = v ?? StepType.email),
          ),
        ),
        SizedBox(width: 10.px),
        ElevatedButton(onPressed: () => widget.onAdd(_type), child: const Text('+ Add step')),
      ],
    );
  }
}

const _stepLabels = {
  StepType.email: 'EMAIL',
  StepType.sms: 'SMS',
  StepType.wait: 'WAIT',
  StepType.addTag: '+ TAG',
  StepType.removeTag: '− TAG',
  StepType.notify: 'NOTIFY',
  StepType.ifCond: 'IF',
  StepType.stopAll: 'STOP',
};

class _StepCard extends StatefulWidget {
  final WorkflowStep step;
  final bool isFirst;
  final bool isLast;
  final List<Map<String, dynamic>> emailTemplates;
  final List<Map<String, dynamic>> smsTemplates;
  final ValueChanged<WorkflowStep> onChanged;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _StepCard({
    super.key,
    required this.step,
    required this.isFirst,
    required this.isLast,
    required this.emailTemplates,
    required this.smsTemplates,
    required this.onChanged,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  late final _valueController = TextEditingController(text: widget.step.value ?? '');
  late final _textController = TextEditingController(text: widget.step.notifyText ?? '');
  late final _amountController = TextEditingController(text: widget.step.waitAmount?.toString() ?? '10');

  @override
  void dispose() {
    _valueController.dispose();
    _textController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;

    return Card(
      margin: EdgeInsets.only(bottom: 10.px),
      child: Padding(
        padding: EdgeInsets.all(12.px),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(_stepLabels[step.type] ?? step.type.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.px, color: Colors.grey[700])),
                const Spacer(),
                IconButton(onPressed: widget.isFirst ? null : widget.onMoveUp, icon: const Icon(Icons.arrow_upward, size: 16), visualDensity: VisualDensity.compact),
                IconButton(onPressed: widget.isLast ? null : widget.onMoveDown, icon: const Icon(Icons.arrow_downward, size: 16), visualDensity: VisualDensity.compact),
                IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.close, size: 18), visualDensity: VisualDensity.compact),
              ],
            ),
            _fields(step),
          ],
        ),
      ),
    );
  }

  Widget _fields(WorkflowStep step) {
    switch (step.type) {
      case StepType.email:
        return _templateDropdown(widget.emailTemplates, step.templateId, (id) => widget.onChanged(_copy(step, templateId: id)));
      case StepType.sms:
        return _templateDropdown(widget.smsTemplates, step.templateId, (id) => widget.onChanged(_copy(step, templateId: id)));
      case StepType.wait:
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount', isDense: true),
                onChanged: (v) => widget.onChanged(_copy(step, waitAmount: int.tryParse(v) ?? 0)),
              ),
            ),
            SizedBox(width: 10.px),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: step.waitUnit ?? 'min',
                decoration: const InputDecoration(labelText: 'Unit', isDense: true),
                items: const [
                  DropdownMenuItem(value: 'min', child: Text('Minutes')),
                  DropdownMenuItem(value: 'hour', child: Text('Hours')),
                  DropdownMenuItem(value: 'day', child: Text('Days')),
                ],
                onChanged: (v) => widget.onChanged(_copy(step, waitUnit: v)),
              ),
            ),
          ],
        );
      case StepType.addTag:
      case StepType.removeTag:
        return TextField(
          controller: _valueController,
          decoration: const InputDecoration(labelText: 'Tag', isDense: true, hintText: 'engaged-seller'),
          onChanged: (v) => widget.onChanged(_copy(step, value: v)),
        );
      case StepType.notify:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: step.value ?? 'owner',
              decoration: const InputDecoration(labelText: 'Notify', isDense: true),
              items: const [
                DropdownMenuItem(value: 'owner', child: Text('Profile owner')),
                DropdownMenuItem(value: 'sales', child: Text('All Sales Reps')),
                DropdownMenuItem(value: 'support', child: Text('All Support')),
                DropdownMenuItem(value: 'super', child: Text('Super Admins')),
              ],
              onChanged: (v) => widget.onChanged(_copy(step, value: v)),
            ),
            SizedBox(height: 8.px),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(labelText: 'Message', isDense: true, hintText: 'Automation alert: {{name}}'),
              onChanged: (v) => widget.onChanged(_copy(step, notifyText: v)),
            ),
          ],
        );
      case StepType.ifCond:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: step.cond ?? 'no_reply',
              decoration: const InputDecoration(labelText: 'Condition', isDense: true),
              items: const [
                DropdownMenuItem(value: 'no_reply', child: Text('No response yet')),
                DropdownMenuItem(value: 'has_tag', child: Text('Has tag…')),
                DropdownMenuItem(value: 'clicked', child: Text('Link clicked')),
              ],
              onChanged: (v) => widget.onChanged(_copy(step, cond: v)),
            ),
            SizedBox(height: 8.px),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(labelText: 'Tag (for has-tag)', isDense: true),
              onChanged: (v) => widget.onChanged(_copy(step, value: v)),
            ),
            SizedBox(height: 8.px),
            DropdownButtonFormField<String>(
              initialValue: step.ifFalse ?? 'stop',
              decoration: const InputDecoration(labelText: 'Else', isDense: true),
              items: const [
                DropdownMenuItem(value: 'stop', child: Text('Stop')),
                DropdownMenuItem(value: 'skip', child: Text('Skip next step')),
              ],
              onChanged: (v) => widget.onChanged(_copy(step, ifFalse: v)),
            ),
          ],
        );
      case StepType.stopAll:
        return const Text('Ends every other active sequence for the contact', style: TextStyle(color: Colors.grey));
    }
  }

  Widget _templateDropdown(List<Map<String, dynamic>> templates, String? selected, ValueChanged<String?> onChanged) {
    if (templates.isEmpty) {
      return const Text('No templates available yet.', style: TextStyle(color: Colors.grey));
    }
    return DropdownButtonFormField<String>(
      initialValue: templates.any((t) => t['_id'] == selected) ? selected : null,
      decoration: const InputDecoration(labelText: 'Template', isDense: true),
      items: templates.map((t) => DropdownMenuItem(value: t['_id']?.toString(), child: Text(t['name']?.toString() ?? '—'))).toList(),
      onChanged: onChanged,
    );
  }

  WorkflowStep _copy(
    WorkflowStep step, {
    String? templateId,
    int? waitAmount,
    String? waitUnit,
    String? value,
    String? notifyText,
    String? cond,
    String? ifFalse,
  }) {
    return WorkflowStep(
      id: step.id,
      type: step.type,
      templateId: templateId ?? step.templateId,
      waitAmount: waitAmount ?? step.waitAmount,
      waitUnit: waitUnit ?? step.waitUnit,
      value: value ?? step.value,
      notifyText: notifyText ?? step.notifyText,
      cond: cond ?? step.cond,
      ifFalse: ifFalse ?? step.ifFalse,
    );
  }
}
