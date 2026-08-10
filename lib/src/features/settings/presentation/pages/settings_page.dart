import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/stage.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/entities/user.dart';
import 'package:trudeals_realty_crm/src/features/settings/domain/repositories/settings_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<Stage> _stages = [];
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = getIt<SettingsRepository>();
    final results = await Future.wait([
      repo.getStages(),
      repo.getUsers(),
    ]);

    results[0].fold(ifLeft: (e) {}, ifRight: (list) => _stages = list as List<Stage>);
    results[1].fold(ifLeft: (e) {}, ifRight: (list) => _users = list as List<User>);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 34.px, vertical: 20.px),
      children: [
        _Panel(
          title: 'Pipeline stages & permissions',
          trailing: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 11.px, vertical: 6.px)),
            child: const Text('+ Add stage'),
          ),
          child: Column(
            children: _stages.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return _StageRow(
                index: i,
                stage: s,
                isFirst: i == 0,
                isLast: i == _stages.length - 1,
              );
            }).toList(),
          ),
        ),
        _Panel(
          title: 'Team seats',
          child: Column(
            children: [
              ..._users.map((u) => _UserRow(user: u)),
              Padding(
                padding: EdgeInsets.all(20.px),
                child: Text(
                  'Seats become real logins in the server build. For now, switch users in the sidebar to see each seat\'s view and permissions.',
                  style: TextStyle(fontSize: 11.px, color: TruDealsColors.inkSoft),
                ),
              ),
            ],
          ),
        ),
        _Panel(
          title: 'Integrations',
          child: Padding(
            padding: EdgeInsets.all(20.px),
            child: Text(
              'Twilio (SMS & voice), Website forms, and Calendar sync (Google / Microsoft 365) ship with the server build via OAuth.',
              style: TextStyle(fontSize: 13.5.px, color: TruDealsColors.inkSoft, height: 1.55),
            ),
          ),
        ),
      ],
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

class _StageRow extends StatelessWidget {
  final int index;
  final Stage stage;
  final bool isFirst;
  final bool isLast;

  const _StageRow({required this.index, required this.stage, required this.isFirst, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 10.px),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0EFE9))),
      ),
      child: Row(
        children: [
          Column(
            children: [
              IconButton(onPressed: isFirst ? null : () {}, icon: const Icon(Icons.arrow_upward, size: 14)),
              IconButton(onPressed: isLast ? null : () {}, icon: const Icon(Icons.arrow_downward, size: 14)),
            ],
          ),
          SizedBox(width: 10.px),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stage.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Permissions: ${stage.roles.join(", ")}', style: const TextStyle(fontSize: 12, color: TruDealsColors.inkSoft)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final User user;
  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.px, vertical: 11.px),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0EFE9))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16.px,
            backgroundColor: TruDealsColors.sageMist,
            child: Text(user.name[0], style: TextStyle(fontSize: 13.px, fontWeight: FontWeight.bold, color: TruDealsColors.sageDeep)),
          ),
          SizedBox(width: 12.px),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${user.dept} · ${user.phone ?? "no seat number"}', style: const TextStyle(fontSize: 12, color: TruDealsColors.inkSoft)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.px, vertical: 3.px),
            decoration: BoxDecoration(color: TruDealsColors.sageMist, borderRadius: BorderRadius.circular(99.px)),
            child: Text(user.role.name.toUpperCase(), style: TextStyle(fontSize: 10.5.px, fontWeight: FontWeight.w700, color: TruDealsColors.sageDeep)),
          ),
          SizedBox(width: 10.px),
          TextButton(onPressed: () {}, child: const Text('Manage', style: TextStyle(color: TruDealsColors.sageDeep))),
        ],
      ),
    );
  }
}
