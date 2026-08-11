import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/entities/user.dart';
import 'package:trudeals_realty_crm/src/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/pipeline_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/stage.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/widgets/contact_drawer.dart';

bool canMoveToStage(Stage stage, UserRole role) {
  if (role == UserRole.superAdmin) return true;
  return stage.roles.contains(role.key);
}

class PipelinePage extends StatelessWidget {
  const PipelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PipelineCubit, PipelineState>(
      builder: (context, state) {
        if (state.isLoading && state.contacts.isEmpty && state.stages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.stages.isEmpty) {
          return _ErrorState(
            message: state.errorMessage ?? "Couldn't load the pipeline.",
            onRetry: () => context.read<PipelineCubit>().refresh(),
          );
        }

        final role = (context.watch<AuthCubit>().state as Authenticated?)?.user.role ?? UserRole.sales;

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 34.px),
          itemCount: state.stages.length,
          itemBuilder: (context, index) {
            final stage = state.stages[index];
            final contactsInStage = state.contacts.where((c) => c.stage == stage.key).toList();
            final locked = !canMoveToStage(stage, role);

            return _PipelineColumn(
              stage: stage,
              contacts: contactsInStage,
              locked: locked,
              userName: state.userName,
              onDrop: (contactId) async {
                final messenger = ScaffoldMessenger.of(context);
                if (locked) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Your role isn\'t permissioned to move profiles into "${stage.label}".')),
                  );
                  return;
                }
                final error = await context.read<PipelineCubit>().moveContact(contactId, stage.key);
                if (error != null) {
                  messenger.showSnackBar(SnackBar(content: Text(error)));
                }
              },
            );
          },
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: TextStyle(color: TruDealsColors.inkSoft), textAlign: TextAlign.center),
          SizedBox(height: 12.px),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _PipelineColumn extends StatelessWidget {
  final Stage stage;
  final List<Contact> contacts;
  final bool locked;
  final Function(String) onDrop;
  final String Function(String?) userName;

  const _PipelineColumn({
    required this.stage,
    required this.contacts,
    required this.locked,
    required this.onDrop,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280.px,
      margin: EdgeInsets.only(right: 16.px, top: 20.px, bottom: 20.px),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3EE),
        borderRadius: BorderRadius.circular(10.px),
        border: Border.all(color: TruDealsColors.line),
      ),
      child: DragTarget<String>(
        onAcceptWithDetails: (details) => onDrop(details.data),
        builder: (context, candidateData, rejectedData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.px, 16.px, 16.px, 12.px),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        stage.label.toUpperCase(),
                        style: TextStyle(fontSize: 12.px, fontWeight: FontWeight.w700, color: TruDealsColors.charcoalSoft),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (locked) Padding(padding: EdgeInsets.only(left: 4.px), child: const Icon(Icons.lock_outline, size: 13)),
                    SizedBox(width: 6.px),
                    Text(
                      contacts.length.toString(),
                      style: TextStyle(fontSize: 12.px, fontWeight: FontWeight.w600, color: TruDealsColors.inkSoft),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: contacts.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(16.px),
                        child: Text('No profiles', style: TextStyle(fontSize: 12.px, color: TruDealsColors.inkSoft)),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 10.px),
                        itemCount: contacts.length,
                        itemBuilder: (context, index) => _PipelineCard(contact: contacts[index], userName: userName),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PipelineCard extends StatelessWidget {
  final Contact contact;
  final String Function(String?) userName;
  const _PipelineCard({required this.contact, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: contact.id,
      feedback: Material(
        color: Colors.transparent,
        child: _CardContent(contact: contact, userName: userName, isFeedback: true),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: _CardContent(contact: contact, userName: userName)),
      child: _CardContent(contact: contact, userName: userName),
    );
  }
}

class _CardContent extends StatelessWidget {
  final Contact contact;
  final String Function(String?) userName;
  final bool isFeedback;
  const _CardContent({required this.contact, required this.userName, this.isFeedback = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showContactDrawer(context, contact.id),
      child: Container(
        width: 258.px,
        margin: EdgeInsets.only(bottom: 10.px),
        padding: EdgeInsets.all(14.px),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.px),
          border: Border.all(color: TruDealsColors.line),
          boxShadow: isFeedback ? [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 10, offset: const Offset(0, 4))] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.px),
            Text(
              contact.propertyAddress?.isNotEmpty == true ? contact.propertyAddress! : 'No address',
              style: TextStyle(fontSize: 12.px, color: TruDealsColors.inkSoft),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 10.px),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${(contact.dealValue / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontFamily: 'DM Mono', fontWeight: FontWeight.w600)),
                if (contact.priority == Priority.high)
                  const Icon(Icons.priority_high, color: TruDealsColors.red, size: 14),
              ],
            ),
            if (contact.assignedTo != null) ...[
              SizedBox(height: 5.px),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 12, color: TruDealsColors.inkSoft),
                  SizedBox(width: 4.px),
                  Expanded(
                    child: Text(
                      userName(contact.assignedTo),
                      style: TextStyle(fontSize: 11.px, color: TruDealsColors.inkSoft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
