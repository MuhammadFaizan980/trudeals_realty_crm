import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import '../../domain/entities/contact.dart';
import '../../domain/entities/communication.dart';
import '../../domain/entities/stage.dart';
import '../cubits/contact_detail_cubit.dart';

class ContactDrawer extends StatefulWidget {
  final String contactId;
  const ContactDrawer({super.key, required this.contactId});

  @override
  State<ContactDrawer> createState() => _ContactDrawerState();
}

class _ContactDrawerState extends State<ContactDrawer> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ContactDetailCubit>()..loadContact(widget.contactId),
      child: Container(
        width: 540.px,
        color: Colors.white,
        child: SafeArea(
          left: false, // Drawer is on the right
          child: BlocBuilder<ContactDetailCubit, ContactDetailState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              final contact = state.contact;
              if (contact == null) return const Center(child: Text('Contact not found'));

              return Column(
                children: [
                  _Header(contact: contact),
                  _Tabs(controller: _tabController),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _OverviewTab(state: state),
                        _MessagesTab(state: state),
                        _LogTab(state: state),
                      ],
                    ),
                  ),
                  _Footer(contact: contact),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Contact contact;
  const _Header({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.px, 20.px, 24.px, 12.px),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: TruDealsColors.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contact.name, style: GoogleFonts.dmSerifDisplay(fontSize: 23.px)),
                    Text(contact.propertyAddress ?? 'No property address yet', style: TextStyle(fontSize: 13.5.px, color: TruDealsColors.inkSoft)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          SizedBox(height: 9.px),
          Wrap(
            spacing: 6.px,
            children: [
              _Tag(label: contact.plan.toUpperCase()),
              _Tag(label: contact.stage.toUpperCase()),
              _Tag(label: '${contact.priority.name.toUpperCase()} PRIORITY'),
            ],
          ),
          SizedBox(height: 12.px),
          Row(
            children: [
              _QuickAction(
                icon: Icons.call,
                label: 'Call',
                onTap: () => _launchURL('tel:${contact.phone}'),
              ),
              SizedBox(width: 8.px),
              _QuickAction(icon: Icons.calendar_today, label: 'Schedule call back', onTap: () {}),
              SizedBox(width: 8.px),
              _QuickAction(
                icon: Icons.email_outlined,
                label: 'Email',
                onTap: () => _launchURL('mailto:${contact.email}'),
              ),
              SizedBox(width: 8.px),
              _QuickAction(
                icon: Icons.sms_outlined,
                label: 'Text',
                onTap: () => _launchURL('sms:${contact.phone}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.px, vertical: 3.px),
      decoration: BoxDecoration(color: TruDealsColors.sageMist, borderRadius: BorderRadius.circular(99.px)),
      child: Text(label, style: TextStyle(fontSize: 10.5.px, fontWeight: FontWeight.w700, color: TruDealsColors.sageDeep)),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.px, vertical: 6.px),
        decoration: BoxDecoration(border: Border.all(color: TruDealsColors.line), borderRadius: BorderRadius.circular(8.px)),
        child: Row(
          children: [
            Icon(icon, size: 14.px),
            SizedBox(width: 6.px),
            Text(label, style: TextStyle(fontSize: 12.5.px, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final TabController controller;
  const _Tabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBFAF7),
      child: TabBar(
        controller: controller,
        labelColor: TruDealsColors.sageDeep,
        unselectedLabelColor: TruDealsColors.inkSoft,
        indicatorColor: TruDealsColors.sageDeep,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Messages'),
          Tab(text: 'Security log'),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final ContactDetailState state;
  const _OverviewTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final contact = state.contact!;
    return ListView(
      padding: EdgeInsets.all(24.px),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          childAspectRatio: 2.5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _InfoCell(label: 'Phone', value: contact.phone ?? '—', mono: true),
            _InfoCell(label: 'Email', value: contact.email ?? '—'),
            _InfoCell(label: 'Source', value: contact.source ?? '—'),
            _InfoCell(label: 'Follow-up', value: contact.followUp != null ? DateFormat('MMM d').format(contact.followUp!) : '—', color: Colors.red),
          ],
        ),
        SizedBox(height: 24.px),
        const _SectionHeader(title: 'Tags'),
        Wrap(
          spacing: 6.px,
          children: contact.tags.map((t) => _Tag(label: t)).toList(),
        ),
        SizedBox(height: 24.px),
        const _SectionHeader(title: 'Scheduled call backs'),
        if (contact.followUp != null)
           ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(DateFormat('MMM d, h:mm a').format(contact.followUp!)),
            subtitle: const Text('Call back reminder'),
            trailing: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final Color? color;
  const _InfoCell({required this.label, required this.value, this.mono = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 11.px, fontWeight: FontWeight.w700, color: TruDealsColors.inkSoft)),
        Text(value, style: TextStyle(fontSize: 14.px, fontFamily: mono ? 'DM Mono' : null, color: color)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.px),
      child: Text(title, style: TextStyle(fontSize: 14.px, fontWeight: FontWeight.w700)),
    );
  }
}

class _MessagesTab extends StatelessWidget {
  final ContactDetailState state;
  const _MessagesTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(24.px),
      itemCount: state.communications.length,
      itemBuilder: (context, index) {
        final comm = state.communications[index];
        final isOut = comm.direction == CommDirection.outbound;
        return Align(
          alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(bottom: 10.px),
            padding: EdgeInsets.all(12.px),
            decoration: BoxDecoration(
              color: isOut ? TruDealsColors.sageDeep : const Color(0xFFEFEEE8),
              borderRadius: BorderRadius.circular(12.px),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${comm.channel.name.toUpperCase()} · ${DateFormat('MMM d, h:mm a').format(comm.timestamp)}',
                  style: TextStyle(fontSize: 10.5.px, color: isOut ? Colors.white70 : TruDealsColors.inkSoft),
                ),
                Text(comm.body, style: TextStyle(color: isOut ? Colors.white : TruDealsColors.ink)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LogTab extends StatelessWidget {
  final ContactDetailState state;
  const _LogTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(24.px),
      itemCount: state.activities.length,
      itemBuilder: (context, index) {
        final act = state.activities[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 14.px),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 4, backgroundColor: TruDealsColors.sage),
              SizedBox(width: 14.px),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('MMM d, h:mm a').format(act.timestamp)} · ${act.type} · ${act.by ?? "System"} 🔒',
                      style: TextStyle(fontSize: 11.5.px, color: TruDealsColors.inkSoft, fontFamily: 'DM Mono'),
                    ),
                    Text(act.text, style: TextStyle(fontSize: 13.5.px)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  final Contact contact;
  const _Footer({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(13.px),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: TruDealsColors.line))),
      child: Row(
        children: [
          Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Edit'))),
          SizedBox(width: 9.px),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showTransferDialog(context),
              child: const Text('Transfer'),
            ),
          ),
          SizedBox(width: 9.px),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _showStageDialog(context),
              child: const Text('Advance stage →'),
            ),
          ),
        ],
      ),
    );
  }

  void _showStageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _StageChooserDialog(contact: contact),
    );
  }

  void _showTransferDialog(BuildContext context) {
    // Logic for transfer dialog
  }
}

class _StageChooserDialog extends StatelessWidget {
  final Contact contact;
  const _StageChooserDialog({required this.contact});

  @override
  Widget build(BuildContext context) {
    // Mock stages for now
    final List<Stage> stages = const [
      Stage(key: 'new', label: 'New Lead', roles: ['sales'], sortOrder: 0),
      Stage(key: 'contacted', label: 'Contacted', roles: ['sales'], sortOrder: 1),
      Stage(key: 'appt', label: 'Listing Appt', roles: ['sales'], sortOrder: 2),
      Stage(key: 'signed', label: 'Agreement Signed', roles: ['sales'], sortOrder: 3),
      Stage(key: 'photos', label: 'Order Photos', roles: ['sales'], sortOrder: 4),
      Stage(key: 'sign', label: 'Order Sign', roles: ['sales'], sortOrder: 5),
      Stage(key: 'active', label: 'Active Listing', roles: ['sales'], sortOrder: 6),
      Stage(key: 'contract', label: 'Under Contract', roles: ['sales'], sortOrder: 7),
      Stage(key: 'closed', label: 'Closed', roles: ['sales'], sortOrder: 8),
    ];

    return AlertDialog(
      title: const Text('Change stage'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: stages.length,
          itemBuilder: (context, index) {
            final s = stages[index];
            final isCurrent = contact.stage == s.key;
            return ListTile(
              title: Text(s.label),
              trailing: isCurrent ? const Text('CURRENT', style: TextStyle(color: TruDealsColors.sageDeep, fontWeight: FontWeight.bold)) : null,
              onTap: isCurrent ? null : () {
                context.read<ContactDetailCubit>().updateStage(s.key);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }
}
