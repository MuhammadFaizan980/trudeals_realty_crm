import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:trudeals_realty_crm/src/features/calendar/domain/entities/callback_event.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/presentation/cubits/dashboard_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/widgets/contact_drawer.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/usecases/get_contacts_usecase.dart';

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
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => context.read<DashboardCubit>().loadDashboard(),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 34.px, vertical: 20.px),
            children: [
              if (state.stats != null)
                _StatsRow(
                  stats: state.stats!,
                  expandedSegment: _expandedSegment,
                  onSegmentTap: (seg) => setState(() => _expandedSegment = _expandedSegment == seg ? null : seg),
                ),
              if (_expandedSegment != null) ...[
                SizedBox(height: 24.px),
                _ExpandedSegmentPanel(
                  segment: _expandedSegment!,
                  onCollapse: () => setState(() => _expandedSegment = null),
                ),
              ],
              SizedBox(height: 24.px),
              _DashboardPanel(
                title: "Today's schedule",
                child: state.schedule.isEmpty
                    ? const _EmptyState(message: 'Nothing scheduled today.')
                    : Column(
                        children: state.schedule.map((e) => _ScheduleTile(event: e)).toList(),
                      ),
              ),
              const _DashboardPanel(
                title: "Upcoming follow-ups",
                child: _EmptyState(message: 'No follow-ups scheduled.'),
              ),
              const _DashboardPanel(
                title: "Recent activity",
                child: _EmptyState(message: 'No recent activity.'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final DashboardStats stats;
  final String? expandedSegment;
  final Function(String) onSegmentTap;

  const _StatsRow({
    required this.stats,
    this.expandedSegment,
    required this.onSegmentTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
      return GridView.count(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14.px,
        mainAxisSpacing: 14.px,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StatCard(
            label: 'Active leads',
            value: stats.totalLeads.toString(),
            hint: 'New through appointment',
            isExpanded: expandedSegment == 'leads',
            onTap: () => onSegmentTap('leads'),
          ),
          _StatCard(
            label: 'Listings in play',
            value: stats.activeDeals.toString(),
            hint: 'Signed through under contract',
            isExpanded: expandedSegment == 'listings',
            onTap: () => onSegmentTap('listings'),
          ),
          _StatCard(
            label: 'In support',
            value: '0',
            hint: 'New Sales Customer Support',
            isExpanded: expandedSegment == 'support',
            onTap: () => onSegmentTap('support'),
          ),
          _StatCard(
            label: 'Pipeline value',
            value: '\$${(stats.pipelineValue / 1000).toStringAsFixed(0)}k',
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
      child: Container(
        padding: EdgeInsets.all(18.px),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.px),
          border: Border.all(
            color: isExpanded ? TruDealsColors.sageDeep : TruDealsColors.line,
            width: isExpanded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(13), offset: const Offset(0, 1), blurRadius: 2),
            BoxShadow(color: Colors.black.withAlpha(15), offset: const Offset(0, 4), blurRadius: 14),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(fontSize: 11.5.px, letterSpacing: 0.1, fontWeight: FontWeight.w600, color: TruDealsColors.inkSoft),
            ),
            SizedBox(height: 8.px),
            Text(value, style: GoogleFonts.dmSerifDisplay(fontSize: 30.px, height: 1.1)),
            SizedBox(height: 6.px),
            Text(hint, style: TextStyle(fontSize: 12.px, color: TruDealsColors.inkSoft)),
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
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ContactDrawer(contactId: event.contactId),
        );
      },
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
                  Text(event.contactName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(event.note ?? 'Call back', style: TextStyle(fontSize: 12.5.px, color: TruDealsColors.inkSoft)),
                ],
              ),
            ),
            Text('Call back', style: TextStyle(fontSize: 12.px, color: TruDealsColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _ExpandedSegmentPanel extends StatefulWidget {
  final String segment;
  final VoidCallback onCollapse;
  const _ExpandedSegmentPanel({required this.segment, required this.onCollapse});

  @override
  State<_ExpandedSegmentPanel> createState() => _ExpandedSegmentPanelState();
}

class _ExpandedSegmentPanelState extends State<_ExpandedSegmentPanel> {
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<GetContactsUseCase>().call();
    result.fold(
      ifLeft: (e) => setState(() => _isLoading = false),
      ifRight: (list) {
        final filtered = switch (widget.segment) {
          'leads' => list.where((c) => ['new', 'contacted', 'appt'].contains(c.stage)).toList(),
          'listings' => list.where((c) => ['signed', 'active', 'contract'].contains(c.stage)).toList(),
          'support' => list.where((c) => c.stage == 'support').toList(),
          _ => list,
        };
        setState(() {
          _contacts = filtered;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.segment) {
      'leads' => 'Active leads',
      'listings' => 'Listings in play',
      'support' => 'In support',
      'pipeline' => 'Open pipeline',
      _ => '',
    };

    return _DashboardPanel(
      title: '$title · ${_contacts.length}',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ..._contacts.map((c) => _SegmentItem(contact: c)),
                Padding(
                  padding: EdgeInsets.all(12.px),
                  child: TextButton(onPressed: widget.onCollapse, child: const Text('Collapse')),
                )
              ],
            ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  final Contact contact;
  const _SegmentItem({required this.contact});

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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 11.px),
        child: Row(
          children: [
             Container(
              padding: EdgeInsets.symmetric(horizontal: 9.px, vertical: 4.px),
              decoration: BoxDecoration(color: TruDealsColors.sageMist, borderRadius: BorderRadius.circular(6.px)),
              child: Text(contact.stage.toUpperCase(), style: TextStyle(fontFamily: 'DM Mono', fontSize: 12.5.px, color: TruDealsColors.sageDeep)),
            ),
            SizedBox(width: 14.px),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${contact.propertyAddress ?? ""} · ${contact.assignedTo}', style: TextStyle(fontSize: 12.5.px, color: TruDealsColors.inkSoft)),
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
