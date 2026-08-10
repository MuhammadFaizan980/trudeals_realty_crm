import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import '../../domain/entities/workflow.dart';
import '../cubits/workflow_cubit.dart';
import 'workflow_editor_page.dart';

class WorkflowListPage extends StatelessWidget {
  const WorkflowListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<WorkflowCubit>()..loadWorkflows(),
      child: const _WorkflowView(),
    );
  }
}

class _WorkflowView extends StatelessWidget {
  const _WorkflowView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkflowCubit, WorkflowState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

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
                "Event-driven, rules-based marketing automation. Workflows fire when their trigger happens — a tag added, a form submitted, a stage change, or a link click — then run their steps in order.",
                style: TextStyle(fontSize: 12.5.px, color: TruDealsColors.inkSoft),
              ),
            ),
            SizedBox(height: 24.px),
            _Panel(
              title: 'Workflows',
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkflowEditorPage()));
                },
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 11.px, vertical: 6.px)),
                child: const Text('+ New workflow'),
              ),
              child: Column(
                children: state.workflows.map((w) => _WorkflowRow(workflow: w)).toList(),
              ),
            ),
            _Panel(
              title: 'Contacts currently in sequences',
              child: Padding(
                padding: EdgeInsets.all(30.px),
                child: Center(
                  child: Text(
                    'No one is in an active sequence. Submit an intake form or add a trigger tag to a profile to start one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TruDealsColors.inkSoft),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: TextStyle(fontSize: 15.px, fontWeight: FontWeight.bold))),
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

class _WorkflowRow extends StatelessWidget {
  final Workflow workflow;
  const _WorkflowRow({required this.workflow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 13.px),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0EFE9))),
      ),
      child: Row(
        children: [
          Switch(
            value: workflow.isActive,
            onChanged: (v) {
              context.read<WorkflowCubit>().toggleWorkflow(workflow.id, v);
            },
            activeThumbColor: TruDealsColors.sageDeep,
          ),
          SizedBox(width: 12.px),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(workflow.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'IF ${workflow.triggerType.toString().split('.').last.toUpperCase()} = ${workflow.triggerValue ?? "Any"} → ${workflow.steps.length} steps',
                  style: TextStyle(fontSize: 12.5.px, color: TruDealsColors.inkSoft),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '0 active',
                style: TextStyle(fontSize: 10.5.px, color: TruDealsColors.inkSoft),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => WorkflowEditorPage(workflow: workflow)));
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.symmetric(horizontal: 4.px, vertical: 4.px),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Edit', style: TextStyle(color: TruDealsColors.sageDeep)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
