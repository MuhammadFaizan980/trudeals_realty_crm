import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import '../../domain/entities/workflow.dart';
import '../../domain/entities/enrollment_summary.dart';
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
        if (state.isLoading && state.workflows.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null && state.workflows.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.errorMessage!, style: TextStyle(color: TruDealsColors.inkSoft)),
                SizedBox(height: 12.px),
                OutlinedButton(onPressed: () => context.read<WorkflowCubit>().loadWorkflows(), child: const Text('Retry')),
              ],
            ),
          );
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
                onPressed: () async {
                  final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => const WorkflowEditorPage()));
                  if (saved == true && context.mounted) context.read<WorkflowCubit>().loadWorkflows();
                },
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 11.px, vertical: 6.px)),
                child: const Text('+ New workflow'),
              ),
              child: state.workflows.isEmpty
                  ? Padding(padding: EdgeInsets.all(24.px), child: Text('No workflows yet.', style: TextStyle(color: TruDealsColors.inkSoft)))
                  : Column(
                      children: state.workflows.map((w) => _WorkflowRow(workflow: w, activeCount: state.activeCountFor(w.id))).toList(),
                    ),
            ),
            _Panel(
              title: 'Contacts currently in sequences',
              child: state.activeEnrollments.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(30.px),
                      child: Center(
                        child: Text(
                          'No one is in an active sequence. Submit an intake form or add a trigger tag to a profile to start one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: TruDealsColors.inkSoft),
                        ),
                      ),
                    )
                  : Column(children: state.activeEnrollments.map((e) => _EnrollmentRow(summary: e)).toList()),
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

class _WorkflowRow extends StatelessWidget {
  final Workflow workflow;
  final int activeCount;
  const _WorkflowRow({required this.workflow, required this.activeCount});

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
                Text(workflow.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  'IF ${workflow.triggerType.name.toUpperCase()} = ${workflow.triggerValue?.isNotEmpty == true ? workflow.triggerValue : "Any"} → ${workflow.steps.length} steps',
                  style: TextStyle(fontSize: 12.5.px, color: TruDealsColors.inkSoft),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$activeCount active', style: TextStyle(fontSize: 10.5.px, color: TruDealsColors.inkSoft)),
              TextButton(
                onPressed: () async {
                  final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => WorkflowEditorPage(workflow: workflow)));
                  if (saved == true && context.mounted) context.read<WorkflowCubit>().loadWorkflows();
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

class _EnrollmentRow extends StatelessWidget {
  final EnrollmentSummary summary;
  const _EnrollmentRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 12.px),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0EFE9)))),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.px, vertical: 4.px),
            decoration: BoxDecoration(color: TruDealsColors.sageMist, borderRadius: BorderRadius.circular(6.px)),
            child: Text(
              summary.enrollment.nextAt.isAfter(DateTime.now()) ? 'Next: ${DateFormat('MMM d, h:mm a').format(summary.enrollment.nextAt)}' : 'Running',
              style: TextStyle(fontFamily: 'DM Mono', fontSize: 11.px, color: TruDealsColors.sageDeep),
            ),
          ),
          SizedBox(width: 14.px),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary.contactName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(summary.workflowName, style: TextStyle(fontSize: 12.px, color: TruDealsColors.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final error = await context.read<WorkflowCubit>().runEnrollmentNext(summary.enrollment.id);
              if (error != null && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
            },
            child: const Text('Run next'),
          ),
          TextButton(
            onPressed: () async {
              final error = await context.read<WorkflowCubit>().stopEnrollment(summary.enrollment.id);
              if (error != null && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
            },
            child: const Text('Stop', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
