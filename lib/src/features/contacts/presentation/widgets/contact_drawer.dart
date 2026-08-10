import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/entities/user.dart';
import 'package:trudeals_realty_crm/src/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/vendor_order.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/communication.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/contact_detail_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/pipeline_cubit.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/pages/add_contact_page.dart';

/// Opens the contact drawer in whichever presentation actually fits the
/// screen: a full-height bottom sheet on phones, a right-anchored panel on
/// wider screens (closer to the reference web app's slide-in drawer).
/// Every place that used to call showModalBottomSheet(...ContactDrawer...)
/// directly should go through this instead.
Future<void> showContactDrawer(BuildContext context, String contactId) {
  final width = MediaQuery.of(context).size.width;
  final isWide = width >= 700;

  if (isWide) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Contact',
      barrierColor: Colors.black.withAlpha(115),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) => Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: (540.0).clamp(0, width * 0.92),
          height: double.infinity,
          child: ContactDrawer(contactId: contactId),
        ),
      ),
      transitionBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.94,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.px)),
        child: ContactDrawer(contactId: contactId),
      ),
    ),
  );
}

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ContactDetailCubit>()..loadContact(widget.contactId),
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: BlocBuilder<ContactDetailCubit, ContactDetailState>(
            builder: (context, state) {
              if (state.isLoading && state.contact == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final contact = state.contact;
              if (contact == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.errorMessage ?? 'Contact not found'),
                      SizedBox(height: 10.px),
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                    ],
                  ),
                );
              }

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
    final hasPhone = contact.phone?.trim().isNotEmpty == true;
    final hasEmail = contact.email?.trim().isNotEmpty == true;

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
                    Text(
                      contact.propertyAddress?.isNotEmpty == true ? contact.propertyAddress! : 'No property address yet',
                      style: TextStyle(fontSize: 13.5.px, color: TruDealsColors.inkSoft),
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          SizedBox(height: 9.px),
          Wrap(
            spacing: 6.px,
            runSpacing: 6.px,
            children: [
              _Tag(label: contact.plan.toUpperCase()),
              _Tag(label: contact.stage.toUpperCase()),
              _Tag(label: '${contact.priority.name.toUpperCase()} PRIORITY'),
            ],
          ),
          SizedBox(height: 12.px),
          Wrap(
            spacing: 8.px,
            runSpacing: 8.px,
            children: [
              if (hasPhone) _QuickAction(icon: Icons.call, label: 'Call', onTap: () => _launchURL(context, 'tel:${contact.phone}')),
              _QuickAction(icon: Icons.calendar_today, label: 'Schedule call back', onTap: () => _openScheduleCallback(context)),
              if (hasEmail) _QuickAction(icon: Icons.email_outlined, label: 'Email', onTap: () => _launchURL(context, 'mailto:${contact.email}')),
              if (hasPhone) _QuickAction(icon: Icons.sms_outlined, label: 'Text', onTap: () => _launchURL(context, 'sms:${contact.phone}')),
            ],
          ),
          if (contact.orders.isNotEmpty) ...[
            SizedBox(height: 10.px),
            Wrap(
              spacing: 8.px,
              runSpacing: 8.px,
              children: [
                if (contact.orders['photos'] != null) _OrderChip(icon: '📷', label: 'Photos', order: contact.orders['photos']!),
                if (contact.orders['sign'] != null) _OrderChip(icon: '🪧', label: 'Sign', order: contact.orders['sign']!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await canLaunchUrl(uri);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text("Couldn't open that — no app is configured to handle it.")));
      return;
    }
    await launchUrl(uri);
  }

  void _openScheduleCallback(BuildContext context) {
    final cubit = context.read<ContactDetailCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(value: cubit, child: const _ScheduleCallbackDialog()),
    );
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
      borderRadius: BorderRadius.circular(8.px),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.px, vertical: 6.px),
        decoration: BoxDecoration(border: Border.all(color: TruDealsColors.line), borderRadius: BorderRadius.circular(8.px)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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

class _OrderChip extends StatelessWidget {
  final String icon;
  final String label;
  final VendorOrder order;
  const _OrderChip({required this.icon, required this.label, required this.order});

  @override
  Widget build(BuildContext context) {
    final kind = label == 'Photos' ? 'photos' : 'sign';
    return InkWell(
      onTap: () => _openOrderDialog(context, kind, label, order),
      borderRadius: BorderRadius.circular(99.px),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.px, vertical: 6.px),
        decoration: BoxDecoration(
          border: Border.all(color: TruDealsColors.sageDeep),
          color: TruDealsColors.sageMist,
          borderRadius: BorderRadius.circular(99.px),
        ),
        child: Text(
          '$icon $label ✓ · ${DateFormat('MMM d').format(order.orderedAt)}',
          style: TextStyle(fontSize: 12.px, fontWeight: FontWeight.w600, color: TruDealsColors.sageDeep),
        ),
      ),
    );
  }

  void _openOrderDialog(BuildContext context, String kind, String label, VendorOrder? existing) {
    final cubit = context.read<ContactDetailCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: _OrderDialog(kind: kind, label: label, existing: existing),
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

class _OverviewTab extends StatefulWidget {
  final ContactDetailState state;
  const _OverviewTab({required this.state});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final _tagController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.state.contact!;
    final upcoming = contact.callbacks.where((cb) => cb.when.isAfter(DateTime.now())).toList()
      ..sort((a, b) => a.when.compareTo(b.when));

    return ListView(
      padding: EdgeInsets.all(24.px),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          childAspectRatio: 2.5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _InfoCell(label: 'Phone', value: contact.phone?.isNotEmpty == true ? contact.phone! : '—', mono: true),
            _InfoCell(label: 'Email', value: contact.email?.isNotEmpty == true ? contact.email! : '—'),
            _InfoCell(label: 'Source', value: contact.source?.isNotEmpty == true ? contact.source! : '—'),
            _InfoCell(
              label: 'Follow-up',
              value: contact.followUp != null ? DateFormat('MMM d').format(contact.followUp!) : '—',
              color: contact.followUp != null && contact.followUp!.isBefore(DateTime.now()) ? Colors.red : null,
            ),
          ],
        ),
        SizedBox(height: 24.px),
        const _SectionHeader(title: 'Tags'),
        Wrap(
          spacing: 6.px,
          runSpacing: 6.px,
          children: [
            ...contact.tags.map((t) => _RemovableTag(
                  label: t,
                  onRemove: _busy ? null : () => _removeTag(context, t),
                )),
          ],
        ),
        SizedBox(height: 8.px),
        SizedBox(
          width: 220.px,
          child: TextField(
            controller: _tagController,
            enabled: !_busy,
            decoration: const InputDecoration(hintText: 'Add tag + Enter', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            onSubmitted: (v) => _addTag(context, v),
          ),
        ),
        SizedBox(height: 24.px),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionHeader(title: 'Scheduled call backs'),
            TextButton(
              onPressed: () {
                final cubit = context.read<ContactDetailCubit>();
                showDialog(context: context, builder: (_) => BlocProvider.value(value: cubit, child: const _ScheduleCallbackDialog()));
              },
              child: const Text('+ Schedule'),
            ),
          ],
        ),
        if (upcoming.isEmpty)
          Padding(padding: EdgeInsets.symmetric(vertical: 10.px), child: Text('No call backs scheduled.', style: TextStyle(color: TruDealsColors.inkSoft)))
        else
          ...upcoming.map((cb) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DateFormat('MMM d, h:mm a').format(cb.when)),
                subtitle: Text(cb.note?.isNotEmpty == true ? cb.note! : 'Call back'),
                trailing: TextButton(
                  onPressed: () => _cancelCallback(context, cb.id),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
              )),
      ],
    );
  }

  Future<void> _addTag(BuildContext context, String value) async {
    final tag = value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    if (tag.isEmpty || _busy) return;
    setState(() => _busy = true);
    final error = await context.read<ContactDetailCubit>().addTag(tag);
    if (!context.mounted) return;
    setState(() => _busy = false);
    _tagController.clear();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      getIt<PipelineCubit>().refresh();
    }
  }

  Future<void> _removeTag(BuildContext context, String tag) async {
    setState(() => _busy = true);
    final error = await context.read<ContactDetailCubit>().removeTag(tag);
    if (!context.mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      getIt<PipelineCubit>().refresh();
    }
  }

  Future<void> _cancelCallback(BuildContext context, String callbackId) async {
    final error = await context.read<ContactDetailCubit>().cancelCallback(callbackId);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _RemovableTag extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;
  const _RemovableTag({required this.label, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.px, vertical: 3.px),
      decoration: BoxDecoration(color: TruDealsColors.sageMist, borderRadius: BorderRadius.circular(99.px)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10.5.px, fontWeight: FontWeight.w700, color: TruDealsColors.sageDeep)),
          if (onRemove != null) ...[
            SizedBox(width: 4.px),
            InkWell(
              onTap: onRemove,
              child: Icon(Icons.close, size: 11.px, color: TruDealsColors.sageDeep),
            ),
          ],
        ],
      ),
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
        Text(value, style: TextStyle(fontSize: 14.px, fontFamily: mono ? 'DM Mono' : null, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
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

class _MessagesTab extends StatefulWidget {
  final ContactDetailState state;
  const _MessagesTab({required this.state});

  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  String _channel = 'email';
  final _bodyController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.state.contact!;
    final thread = [...widget.state.communications]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final canEmail = contact.email?.isNotEmpty == true;
    final canSms = contact.phone?.isNotEmpty == true;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(24.px),
            itemCount: thread.length,
            itemBuilder: (context, index) {
              final comm = thread[index];
              final isOut = comm.direction == CommDirection.outbound;
              return Align(
                alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 380.px),
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
                          '${comm.isAutomated ? '⚙ Automated · ' : ''}${comm.channel.name.toUpperCase()} · ${DateFormat('MMM d, h:mm a').format(comm.timestamp)}',
                          style: TextStyle(fontSize: 10.5.px, color: isOut ? Colors.white70 : TruDealsColors.inkSoft),
                        ),
                        if (comm.subject != null && comm.subject!.isNotEmpty)
                          Text(comm.subject!, style: TextStyle(fontWeight: FontWeight.bold, color: isOut ? Colors.white : TruDealsColors.ink)),
                        Text(comm.body, style: TextStyle(color: isOut ? Colors.white : TruDealsColors.ink)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.all(14.px),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: TruDealsColors.line))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (canEmail)
                    ChoiceChip(
                      label: const Text('Email'),
                      selected: _channel == 'email',
                      onSelected: (_) => setState(() => _channel = 'email'),
                    ),
                  if (canEmail && canSms) SizedBox(width: 8.px),
                  if (canSms)
                    ChoiceChip(
                      label: const Text('SMS'),
                      selected: _channel == 'sms',
                      onSelected: (_) => setState(() => _channel = 'sms'),
                    ),
                  const Spacer(),
                  TextButton(onPressed: _busySafe(_openLogReply), child: const Text('Log customer reply')),
                ],
              ),
              if (!canEmail && !canSms)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.px),
                  child: Text('Add a phone or email on this contact to send a message.', style: TextStyle(color: TruDealsColors.inkSoft, fontSize: 12.px)),
                )
              else ...[
                SizedBox(height: 8.px),
                TextField(
                  controller: _bodyController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Write a message…'),
                ),
                SizedBox(height: 8.px),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _sending ? null : () => _send(context),
                    child: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send & log'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  VoidCallback _busySafe(VoidCallback fn) => _sending ? () {} : fn;

  Future<void> _send(BuildContext context) async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    final cubit = context.read<ContactDetailCubit>();
    final error = _channel == 'email' ? await cubit.sendEmail(body: body) : await cubit.sendSms(body: body);
    if (!context.mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      _bodyController.clear();
    }
  }

  void _openLogReply() {
    final cubit = context.read<ContactDetailCubit>();
    showDialog(context: context, builder: (_) => BlocProvider.value(value: cubit, child: const _LogReplyDialog()));
  }
}

class _LogReplyDialog extends StatefulWidget {
  const _LogReplyDialog();

  @override
  State<_LogReplyDialog> createState() => _LogReplyDialogState();
}

class _LogReplyDialogState extends State<_LogReplyDialog> {
  String _channel = 'email';
  final _bodyController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log customer reply'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _channel,
            decoration: const InputDecoration(labelText: 'Channel'),
            items: const [DropdownMenuItem(value: 'email', child: Text('Email')), DropdownMenuItem(value: 'sms', child: Text('SMS'))],
            onChanged: (v) => setState(() => _channel = v ?? 'email'),
          ),
          SizedBox(height: 12.px),
          TextField(
            controller: _bodyController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: "Their message", hintText: 'Paste what the customer sent back…'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : () => _save(context),
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save to thread'),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;
    setState(() => _saving = true);
    final error = await context.read<ContactDetailCubit>().logReply(channel: _channel, body: body);
    if (!context.mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pop(context);
    }
  }
}

class _LogTab extends StatefulWidget {
  final ContactDetailState state;
  const _LogTab({required this.state});

  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  String _type = 'Note';
  final _textController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activities = [...widget.state.activities]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(24.px).copyWith(bottom: 12.px),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.px),
                decoration: BoxDecoration(color: TruDealsColors.sageMist, borderRadius: BorderRadius.circular(8.px)),
                child: Text(
                  'This log is append-only: every entry is time-stamped with who created it and can never be edited or removed.',
                  style: TextStyle(fontSize: 11.5.px, color: TruDealsColors.inkSoft),
                ),
              ),
              SizedBox(height: 10.px),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _type,
                    items: const ['Note', 'Call', 'Email', 'Text', 'Meeting']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v ?? 'Note'),
                  ),
                  SizedBox(width: 8.px),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(hintText: 'Add a permanent note…', isDense: true),
                    ),
                  ),
                  SizedBox(width: 8.px),
                  ElevatedButton(
                    onPressed: _saving ? null : _addNote,
                    child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 24.px),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final act = activities[index];
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
          ),
        ),
      ],
    );
  }

  Future<void> _addNote() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final error = await context.read<ContactDetailCubit>().addNote(type: _type, text: text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      _textController.clear();
    }
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
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 9.px,
        runSpacing: 9.px,
        children: [
          OutlinedButton(onPressed: () => _editContact(context), child: const Text('Edit contact')),
          OutlinedButton(onPressed: () => _showTransferDialog(context), child: const Text('Transfer contact')),
          ElevatedButton(onPressed: () => _showStageDialog(context), child: const Text('Advance stage →')),
        ],
      ),
    );
  }

  Future<void> _editContact(BuildContext context) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddContactPage(existing: contact)),
    );
    if (updated == true && context.mounted) {
      context.read<ContactDetailCubit>().loadContact(contact.id);
      getIt<PipelineCubit>().refresh();
    }
  }

  void _showStageDialog(BuildContext context) {
    final cubit = context.read<ContactDetailCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(value: cubit, child: _StageChooserDialog(contact: contact)),
    );
  }

  void _showTransferDialog(BuildContext context) {
    final cubit = context.read<ContactDetailCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(value: cubit, child: _TransferDialog(contact: contact)),
    );
  }
}

class _StageChooserDialog extends StatefulWidget {
  final Contact contact;
  const _StageChooserDialog({required this.contact});

  @override
  State<_StageChooserDialog> createState() => _StageChooserDialogState();
}

class _StageChooserDialogState extends State<_StageChooserDialog> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final pipelineCubit = getIt<PipelineCubit>();
    final role = (getIt<AuthCubit>().state as Authenticated?)?.user.role ?? UserRole.sales;

    return StreamBuilder<PipelineState>(
      stream: pipelineCubit.stream,
      initialData: pipelineCubit.state,
      builder: (context, snapshot) {
        final stages = (snapshot.data ?? pipelineCubit.state).stages;
        return AlertDialog(
          title: const Text('Change stage'),
          content: SizedBox(
            width: double.maxFinite,
            child: stages.isEmpty
                ? const Text("Stages haven't loaded yet — close this and try again.")
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: stages.length,
                    itemBuilder: (context, index) {
                      final s = stages[index];
                      final isCurrent = widget.contact.stage == s.key;
                      final allowed = role == UserRole.superAdmin || s.roles.contains(role.key);
                      return ListTile(
                        title: Text(s.label),
                        trailing: isCurrent
                            ? const Text('CURRENT', style: TextStyle(color: TruDealsColors.sageDeep, fontWeight: FontWeight.bold))
                            : (!allowed ? const Icon(Icons.lock_outline, size: 16) : null),
                        enabled: !_busy,
                        onTap: (isCurrent || !allowed || _busy) ? null : () => _pick(context, s.key),
                      );
                    },
                  ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        );
      },
    );
  }

  Future<void> _pick(BuildContext context, String stageKey) async {
    setState(() => _busy = true);
    final error = await context.read<ContactDetailCubit>().updateStage(stageKey);
    if (!context.mounted) return;
    if (error != null) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      getIt<PipelineCubit>().refresh();
      Navigator.pop(context);
    }
  }
}

class _TransferDialog extends StatefulWidget {
  final Contact contact;
  const _TransferDialog({required this.contact});

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  String? _toUserId;
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pipelineCubit = getIt<PipelineCubit>();

    return StreamBuilder<PipelineState>(
      stream: pipelineCubit.stream,
      initialData: pipelineCubit.state,
      builder: (context, snapshot) {
        final users = (snapshot.data ?? pipelineCubit.state).users.where((u) => u.id != widget.contact.assignedTo).toList();
        return AlertDialog(
          title: const Text('Transfer profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (users.isEmpty)
                const Text("No other seats to transfer to yet.")
              else
                DropdownButtonFormField<String>(
                  initialValue: _toUserId,
                  decoration: const InputDecoration(labelText: 'Send to'),
                  items: users.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.name} — ${u.dept}'))).toList(),
                  onChanged: (v) => setState(() => _toUserId = v),
                ),
              SizedBox(height: 12.px),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Handoff note', hintText: 'Closed! Please schedule the welcome call.'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: (_toUserId == null || _saving) ? null : () => _transfer(context),
              child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Transfer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _transfer(BuildContext context) async {
    setState(() => _saving = true);
    final error = await context.read<ContactDetailCubit>().transfer(_toUserId!, note: _noteController.text.trim());
    if (!context.mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      getIt<PipelineCubit>().refresh();
      Navigator.pop(context);
    }
  }
}

class _ScheduleCallbackDialog extends StatefulWidget {
  const _ScheduleCallbackDialog();

  @override
  State<_ScheduleCallbackDialog> createState() => _ScheduleCallbackDialogState();
}

class _ScheduleCallbackDialogState extends State<_ScheduleCallbackDialog> {
  DateTime? _when;
  final _noteController = TextEditingController();
  bool _remind15 = true;
  bool _remind10 = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(hours: 1));
    _when = DateTime(now.year, now.month, now.day, now.hour, (now.minute ~/ 15) * 15);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule call back'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => _pickDateTime(context),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(_when != null ? DateFormat('MMM d, h:mm a').format(_when!) : 'Pick date & time'),
          ),
          SizedBox(height: 12.px),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: "What's the call about?", hintText: 'Review listing agreement…'),
          ),
          SizedBox(height: 8.px),
          CheckboxListTile(
            value: _remind15,
            onChanged: (v) => setState(() => _remind15 = v ?? true),
            title: const Text('15 min before'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _remind10,
            onChanged: (v) => setState(() => _remind10 = v ?? true),
            title: const Text('10 min before'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : () => _save(context),
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Schedule'),
        ),
      ],
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when ?? DateTime.now()));
    if (time == null) return;
    setState(() => _when = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save(BuildContext context) async {
    if (_when == null) return;
    setState(() => _saving = true);
    final error = await context.read<ContactDetailCubit>().scheduleCallback(
          when: _when!,
          note: _noteController.text.trim(),
          remind15: _remind15,
          remind10: _remind10,
        );
    if (!context.mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pop(context);
    }
  }
}

class _OrderDialog extends StatefulWidget {
  final String kind;
  final String label;
  final VendorOrder? existing;
  const _OrderDialog({required this.kind, required this.label, this.existing});

  @override
  State<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<_OrderDialog> {
  late final _companyController = TextEditingController(text: widget.existing?.company ?? '');
  late final _notesController = TextEditingController(text: widget.existing?.notes ?? '');
  DateTime? _eta;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _eta = widget.existing?.eta;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? '${widget.label} ordered' : 'Order ${widget.label.toLowerCase()}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _companyController, decoration: const InputDecoration(labelText: 'Company ordered through')),
          SizedBox(height: 12.px),
          OutlinedButton.icon(
            onPressed: () => _pickEta(context),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(_eta != null ? 'ETA ${DateFormat('MMM d, h:mm a').format(_eta!)}' : 'Set est. delivery (optional)'),
          ),
          SizedBox(height: 12.px),
          TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (optional)')),
        ],
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: _saving ? null : () => _clear(context),
            child: const Text('Clear order', style: TextStyle(color: Colors.red)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : () => _save(context),
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _pickEta(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eta ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_eta ?? DateTime.now()));
    if (time == null) return;
    setState(() => _eta = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save(BuildContext context) async {
    setState(() => _saving = true);
    final error = await context.read<ContactDetailCubit>().placeOrder(
          widget.kind,
          company: _companyController.text.trim(),
          etaAt: _eta,
          notes: _notesController.text.trim(),
        );
    if (!context.mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _clear(BuildContext context) async {
    setState(() => _saving = true);
    final error = await context.read<ContactDetailCubit>().cancelOrder(widget.kind);
    if (!context.mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pop(context);
    }
  }
}

