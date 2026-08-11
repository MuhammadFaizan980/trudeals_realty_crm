import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import 'package:trudeals_realty_crm/src/features/calendar/domain/entities/callback_event.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/presentation/cubits/dashboard_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/widgets/contact_drawer.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/pipeline_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/activity.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/stage.dart';

/// Classifies every *current* stage into "lead" or "listing" for the
/// dashboard's stat cards, anchored on the well-known `signed`/`closed`
/// stage keys the rest of the app already relies on (see `stage != 'closed'`
/// elsewhere) rather than an exhaustive hardcoded list of stage keys. A
/// hardcoded list silently drops any stage the team adds later — confirmed
/// against live data: a custom "New Lead Buying" stage and the stock
/// "Order Photos"/"Order Sign" stages were invisible to the old stat cards.
class _StageBuckets {
  final Set<String> leadKeys;
  final Set<String> listingKeys;
  const _StageBuckets({required this.leadKeys, required this.listingKeys});

  factory _StageBuckets.from(List<Stage> stages) {
    final signedOrder = stages.firstWhereOrNull((s) => s.key == 'signed')?.sortOrder;
    final closedOrder = stages.firstWhereOrNull((s) => s.key == 'closed')?.sortOrder;

    final leads = <String>{};
    final listings = <String>{};
    if (signedOrder != null) {
      for (final s in stages) {
        if (s.key == 'support' || s.key == 'closed') continue;
        if (s.sortOrder < signedOrder) {
          leads.add(s.key);
        } else if (closedOrder != null && s.sortOrder < closedOrder) {
          listings.add(s.key);
        }
      }
    }
    return _StageBuckets(leadKeys: leads, listingKeys: listings);
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DashboardCubit>()..loadDashboard(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  String? _expandedSegment;

  @override
  Widget build(BuildContext context) {
    final pipeline = context.watch<PipelineCubit>().state;
    final contacts = pipeline.contacts.where((c) => !c.deleted).toList();

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, dashState) {
        if (pipeline.isLoading && contacts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (pipeline.errorMessage != null && contacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pipeline.errorMessage!, style: TextStyle(color: TruDealsColors.inkSoft)),
                SizedBox(height: 12.px),
                OutlinedButton(onPressed: () => context.read<PipelineCubit>().refresh(), child: const Text('Retry')),
              ],
            ),
          );
        }

        final buckets = _StageBuckets.from(pipeline.stages);
        final followUps = contacts.where((c) => c.followUp != null && c.stage != 'closed').toList()
          ..sort((a, b) => a.followUp!.compareTo(b.followUp!));
        final recent = contacts
            .expand((c) => c.activities.map((a) => (contact: c, activity: a)))
            .toList()
          ..sort((a, b) => b.activity.timestamp.compareTo(a.activity.timestamp));

        return RefreshIndicator(
          onRefresh: () => Future.wait([
            context.read<PipelineCubit>().refresh(),
            context.read<DashboardCubit>().loadDashboard(),
          ]),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 34.px, vertical: 20.px),
            children: [
              _StatsRow(
                contacts: contacts,
                buckets: buckets,
                expandedSegment: _expandedSegment,
                onSegmentTap: (seg) => setState(() => _expandedSegment = _expandedSegment == seg ? null : seg),
              ),
              if (_expandedSegment != null) ...[
                SizedBox(height: 24.px),
                _ExpandedSegmentPanel(
                  segment: _expandedSegment!,
                  contacts: contacts,
                  buckets: buckets,
                  userName: pipeline.userName,
                  onCollapse: () => setState(() => _expandedSegment = null),
                ),
              ],
              SizedBox(height: 24.px),
              _DashboardPanel(
                title: "Today's schedule",
                child: dashState.todaySchedule.isEmpty
                    ? const _EmptyState(message: 'Nothing scheduled today.')
                    : Column(children: dashState.todaySchedule.map((e) => _ScheduleTile(event: e)).toList()),
              ),
              _DashboardPanel(
                title: 'Upcoming follow-ups',
                child: followUps.isEmpty
                    ? const _EmptyState(message: 'No follow-ups scheduled.')
                    : Column(children: followUps.take(7).map((c) => _FollowUpTile(contact: c)).toList()),
              ),
              _DashboardPanel(
                title: 'Recent activity',
                child: recent.isEmpty
                    ? const _EmptyState(message: 'No recent activity.')
                    : Column(
                        children: recent.take(6).map((r) => _ActivityTile(contact: r.contact, activity: r.activity)).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<Contact> contacts;
  final _StageBuckets buckets;
  final String? expandedSegment;
  final Function(String) onSegmentTap;

  const _StatsRow({required this.contacts, required this.buckets, this.expandedSegment, required this.onSegmentTap});

  @override
  Widget build(BuildContext context) {
    final activeLeads = contacts.where((c) => buckets.leadKeys.contains(c.stage)).length;
    final listingsInPlay = contacts.where((c) => buckets.listingKeys.contains(c.stage)).length;
    final inSupport = contacts.where((c) => c.stage == 'support').length;
    final openPipeline = contacts.where((c) => c.stage != 'closed');
    final pipelineValue = openPipeline.fold(0.0, (sum, c) => sum + c.dealValue);

    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
      return GridView.count(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14.px,
        mainAxisSpacing: 14.px,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.5,
        children: [
          _StatCard(
            label: 'Active leads',
            value: activeLeads.toString(),
            hint: 'Before agreement signed',
            isExpanded: expandedSegment == 'leads',
            onTap: () => onSegmentTap('leads'),
          ),
          _StatCard(
            label: 'Listings in play',
            value: listingsInPlay.toString(),
            hint: 'Signed through under contract',
            isExpanded: expandedSegment == 'listings',
            onTap: () => onSegmentTap('listings'),
          ),
          _StatCard(
            label: 'In support',
            value: inSupport.toString(),
            hint: 'Customer support',
            isExpanded: expandedSegment == 'support',
            onTap: () => onSegmentTap('support'),
          ),
          _StatCard(
            label: 'Pipeline value',
            value: '\$${(pipelineValue / 1000).toStringAsFixed(0)}k',
            hint: 'Open deals',
            isExpanded: expandedSegment == 'pipeline',
            onTap: () => onSegmentTap('pipeline'),
          ),
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final bool isExpanded;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.px),
      child: Container(
        padding: EdgeInsets.all(16.px),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.px),
          border: Border.all(color: isExpanded ? TruDealsColors.sageDeep : TruDealsColors.line, width: isExpanded ? 2 : 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(13), offset: const Offset(0, 1), blurRadius: 2),
            BoxShadow(color: Colors.black.withAlpha(15), offset: const Offset(0, 4), blurRadius: 14),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(fontSize: 11.px, letterSpacing: 0.1, fontWeight: FontWeight.w600, color: TruDealsColors.inkSoft),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 6.px),
            Text(value, style: GoogleFonts.dmSerifDisplay(fontSize: 26.px, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 4.px),
            Text(hint, style: TextStyle(fontSize: 11.px, color: TruDealsColors.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final String title;
  final Widget child;
  const _DashboardPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 22.px),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.px),
        border: Border.all(color: TruDealsColors.line),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), offset: const Offset(0, 1), blurRadius: 2),
          BoxShadow(color: Colors.black.withAlpha(15), offset: const Offset(0, 4), blurRadius: 14),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 15.px),
            child: Text(title, style: TextStyle(fontSize: 15.px, fontWeight: FontWeight.w700)),
          ),
          const Divider(height: 1, color: TruDealsColors.line),
          Padding(padding: EdgeInsets.symmetric(vertical: 6.px), child: child),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(30.px),
      child: Center(
        child: Text(message, style: TextStyle(fontSize: 14.px, color: TruDealsColors.inkSoft)),
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final CallbackEvent event;
  const _ScheduleTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showContactDrawer(context, event.contactId),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 11.px),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9.px, vertical: 4.px),
              decoration: BoxDecoration(color: TruDealsColors.amberBg, borderRadius: BorderRadius.circular(6.px)),
              child: Text(DateFormat('h:mm a').format(event.scheduledAt), style: TextStyle(fontFamily: 'DM Mono', fontSize: 12.5.px, color: TruDealsColors.amber)),
            ),
            SizedBox(width: 14.px),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.contactName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(event.note ?? 'Call back', style: TextStyle(fontSize: 12.5.px, color: TruDealsColors.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpTile extends StatelessWidget {
  final Contact contact;
  const _FollowUpTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    final overdue = contact.followUp!.isBefore(DateTime.now());
    return InkWell(
      onTap: () => showContactDrawer(context, contact.id),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 11.px),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9.px, vertical: 4.px),
              decoration: BoxDecoration(color: overdue ? TruDealsColors.redBg : TruDealsColors.sageMist, borderRadius: BorderRadius.circular(6.px)),
              child: Text(
                (overdue ? 'Overdue · ' : '') + DateFormat('MMM d').format(contact.followUp!),
                style: TextStyle(fontFamily: 'DM Mono', fontSize: 12.px, color: overdue ? TruDealsColors.red : TruDealsColors.sageDeep),
              ),
            ),
            SizedBox(width: 14.px),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(contact.propertyAddress ?? '', style: TextStyle(fontSize: 12.5.px, color: TruDealsColors.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Contact contact;
  final Activity activity;
  const _ActivityTile({required this.contact, required this.activity});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showContactDrawer(context, contact.id),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 11.px),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9.px, vertical: 4.px),
              decoration: BoxDecoration(color: const Color(0xFFEFEEE8), borderRadius: BorderRadius.circular(6.px)),
              child: Text(DateFormat('MMM d').format(activity.timestamp), style: TextStyle(fontFamily: 'DM Mono', fontSize: 12.px, color: TruDealsColors.inkSoft)),
            ),
            SizedBox(width: 14.px),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${activity.type} — ${activity.text}', style: TextStyle(fontSize: 12.5.px, color: TruDealsColors.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedSegmentPanel extends StatelessWidget {
  final String segment;
  final List<Contact> contacts;
  final _StageBuckets buckets;
  final String Function(String?) userName;
  final VoidCallback onCollapse;
  const _ExpandedSegmentPanel({
    required this.segment,
    required this.contacts,
    required this.buckets,
    required this.userName,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (segment) {
      'leads' => 'Active leads',
      'listings' => 'Listings in play',
      'support' => 'In support',
      'pipeline' => 'Open pipeline',
      _ => '',
    };
    final filtered = switch (segment) {
      'leads' => contacts.where((c) => buckets.leadKeys.contains(c.stage)).toList(),
      'listings' => contacts.where((c) => buckets.listingKeys.contains(c.stage)).toList(),
      'support' => contacts.where((c) => c.stage == 'support').toList(),
      'pipeline' => contacts.where((c) => c.stage != 'closed').toList(),
      _ => <Contact>[],
    }..sort((a, b) => (b.dealValue).compareTo(a.dealValue));

    return _DashboardPanel(
      title: '$title · ${filtered.length}',
      child: Column(
        children: [
          if (filtered.isEmpty)
            const _EmptyState(message: 'No profiles in this group right now.')
          else
            ...filtered.map((c) => _SegmentItem(contact: c, ownerName: userName(c.assignedTo))),
          Padding(
            padding: EdgeInsets.all(12.px),
            child: TextButton(onPressed: onCollapse, child: const Text('Collapse')),
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  final Contact contact;
  final String ownerName;
  const _SegmentItem({required this.contact, required this.ownerName});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showContactDrawer(context, contact.id),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 11.px),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9.px, vertical: 4.px),
              decoration: BoxDecoration(color: TruDealsColors.sageMist, borderRadius: BorderRadius.circular(6.px)),
              child: Text(contact.stage.toUpperCase(), style: TextStyle(fontFamily: 'DM Mono', fontSize: 12.px, color: TruDealsColors.sageDeep)),
            ),
            SizedBox(width: 14.px),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    '${contact.propertyAddress?.isNotEmpty == true ? contact.propertyAddress! : ""} · $ownerName',
                    style: TextStyle(fontSize: 12.5.px, color: TruDealsColors.inkSoft),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text('\$${(contact.dealValue / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontFamily: 'DM Mono')),
          ],
        ),
      ),
    );
  }
}
