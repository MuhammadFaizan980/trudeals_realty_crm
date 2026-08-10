import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/pipeline_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/stage.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/widgets/contact_drawer.dart';

class PipelinePage extends StatelessWidget {
  const PipelinePage({super.key});

  final List<Stage> stages = const [
    Stage(key: 'new', label: 'New Lead', roles: ['super', 'sales'], sortOrder: 0),
    Stage(key: 'contacted', label: 'Contacted', roles: ['super', 'sales'], sortOrder: 1),
    Stage(key: 'appt', label: 'Listing Appt', roles: ['super', 'sales'], sortOrder: 2),
    Stage(key: 'signed', label: 'Agreement Signed', roles: ['super', 'sales'], sortOrder: 3),
    Stage(key: 'photos', label: 'Order Photos', roles: ['super', 'sales'], sortOrder: 4),
    Stage(key: 'sign', label: 'Order Sign', roles: ['super', 'sales'], sortOrder: 5),
    Stage(key: 'active', label: 'Active Listing', roles: ['super', 'sales'], sortOrder: 6),
    Stage(key: 'contract', label: 'Under Contract', roles: ['super', 'sales'], sortOrder: 7),
    Stage(key: 'closed', label: 'Closed', roles: ['super', 'sales'], sortOrder: 8),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PipelineCubit>()..loadContacts(),
      child: BlocBuilder<PipelineCubit, PipelineState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 34.px),
            itemCount: stages.length,
            itemBuilder: (context, index) {
              final stage = stages[index];
              final contactsInStage = state.contacts.where((c) => c.stage == stage.key).toList();

              return _PipelineColumn(
                stage: stage,
                contacts: contactsInStage,
                onDrop: (contactId) {
                  context.read<PipelineCubit>().moveContact(contactId, stage.key);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PipelineColumn extends StatelessWidget {
  final Stage stage;
  final List<Contact> contacts;
  final Function(String) onDrop;

  const _PipelineColumn({required this.stage, required this.contacts, required this.onDrop});

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
                    Text(
                      stage.label.toUpperCase(),
                      style: TextStyle(fontSize: 12.px, fontWeight: FontWeight.w700, color: TruDealsColors.charcoalSoft),
                    ),
                    Text(
                      contacts.length.toString(),
                      style: TextStyle(fontSize: 12.px, fontWeight: FontWeight.w600, color: TruDealsColors.inkSoft),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 10.px),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) => _PipelineCard(contact: contacts[index]),
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
  const _PipelineCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: contact.id,
      feedback: Material(
        color: Colors.transparent,
        child: _CardContent(contact: contact, isFeedback: true),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: _CardContent(contact: contact)),
      child: _CardContent(contact: contact),
    );
  }
}

class _CardContent extends StatelessWidget {
  final Contact contact;
  final bool isFeedback;
  const _CardContent({required this.contact, this.isFeedback = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ContactDrawer(contactId: contact.id),
        );
      },
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
            Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 4.px),
            Text(
              contact.propertyAddress ?? 'No address',
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
          ],
        ),
      ),
    );
  }
}
