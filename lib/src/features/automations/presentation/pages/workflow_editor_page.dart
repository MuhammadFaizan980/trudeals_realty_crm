import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:trudeals_realty_crm/src/features/automations/domain/entities/workflow.dart';

class WorkflowEditorPage extends StatefulWidget {
  final Workflow? workflow;
  const WorkflowEditorPage({super.key, this.workflow});

  @override
  State<WorkflowEditorPage> createState() => _WorkflowEditorPageState();
}

class _WorkflowEditorPageState extends State<WorkflowEditorPage> {
  late TextEditingController _nameController;
  late TriggerType _triggerType;
  late List<WorkflowStep> _steps;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workflow?.name ?? '');
    _triggerType = widget.workflow?.triggerType ?? TriggerType.tag;
    _steps = List.from(widget.workflow?.steps ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workflow == null ? 'New workflow' : 'Edit workflow'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(24.px),
        children: [
          Text('Workflow name', style: TextStyle(fontSize: 14.px, fontWeight: FontWeight.bold)),
          TextField(controller: _nameController),
          SizedBox(height: 16.px),
          Text('Trigger (IF...)', style: TextStyle(fontSize: 14.px, fontWeight: FontWeight.bold)),
          DropdownButton<TriggerType>(
            value: _triggerType,
            items: TriggerType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _triggerType = v!),
          ),
          SizedBox(height: 24.px),
          Text('Steps (THEN...)', style: TextStyle(fontSize: 16.px, fontWeight: FontWeight.bold)),
          ..._steps.asMap().entries.map((e) => _StepRow(index: e.key, step: e.value)),
          SizedBox(height: 16.px),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _steps.add(WorkflowStep(id: '${_steps.length}', workflowId: '', stepOrder: _steps.length, type: StepType.email));
              });
            },
            child: const Text('+ Add step'),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final WorkflowStep step;
  const _StepRow({required this.index, required this.step});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.px),
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(step.type.name.toUpperCase()),
        subtitle: Text(step.templateId ?? 'No template selected'),
        trailing: const Icon(Icons.close),
      ),
    );
  }
}
