import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/domain/entities/user.dart';

class TruDealsSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  const TruDealsSidebar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 228.px,
      color: TruDealsColors.charcoal,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 22.px, horizontal: 14.px),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.px),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 21.px,
                          color: Colors.white,
                        ),
                        children: const [
                          TextSpan(text: 'TruDeals'),
                          TextSpan(
                            text: ' Realty',
                            style: TextStyle(color: TruDealsColors.sage),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.px),
                    Text(
                      'BROKERAGE CRM',
                      style: TextStyle(
                        fontSize: 11.px,
                        letterSpacing: 0.14.px,
                        color: const Color(0xFF9AA39A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.px),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _NavButton(
                      index: 0,
                      label: 'Dashboard',
                      icon: Icons.dashboard_outlined,
                      currentIndex: currentIndex,
                      onTap: onIndexChanged,
                    ),
                    _NavButton(
                      index: 1,
                      label: 'Calendar',
                      icon: Icons.calendar_today_outlined,
                      currentIndex: currentIndex,
                      onTap: onIndexChanged,
                    ),
                    _NavButton(
                      index: 2,
                      label: 'Pipeline',
                      icon: Icons.view_kanban_outlined,
                      currentIndex: currentIndex,
                      onTap: onIndexChanged,
                    ),
                    _NavButton(
                      index: 3,
                      label: 'Contacts',
                      icon: Icons.people_outline,
                      currentIndex: currentIndex,
                      onTap: onIndexChanged,
                    ),
                    _NavButton(
                      index: 4,
                      label: 'Automations',
                      icon: Icons.auto_awesome_outlined,
                      currentIndex: currentIndex,
                      onTap: onIndexChanged,
                    ),
                    _NavButton(
                      index: 5,
                      label: 'Intake Forms',
                      icon: Icons.assignment_outlined,
                      currentIndex: currentIndex,
                      onTap: onIndexChanged,
                    ),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        if (state is Authenticated && state.user.role == UserRole.superAdmin) {
                          return _NavButton(
                            index: 6,
                            label: 'Trash',
                            icon: Icons.delete_outline,
                            currentIndex: currentIndex,
                            onTap: onIndexChanged,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    _NavButton(
                      index: 7,
                      label: 'Settings',
                      icon: Icons.settings_outlined,
                      currentIndex: currentIndex,
                      onTap: onIndexChanged,
                    ),
                  ],
                ),
              ),
              const _UserSwitcher(),
              SizedBox(height: 18.px),
              _LogoutButton(),
              SizedBox(height: 12.px),
              const _SidebarFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.px),
      child: InkWell(
        onTap: () => context.read<AuthCubit>().logout(),
        borderRadius: BorderRadius.circular(8.px),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9.px, horizontal: 10.px),
          child: Row(
            children: [
              const Icon(Icons.logout, size: 17, color: Color(0xFFC9CDC8)),
              SizedBox(width: 10.px),
              const Text(
                'Logout',
                style: TextStyle(color: Color(0xFFC9CDC8), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final int index;
  final String label;
  final IconData icon;
  final int currentIndex;
  final Function(int) onTap;

  const _NavButton({
    required this.index,
    required this.label,
    required this.icon,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return Padding(
      padding: EdgeInsets.only(bottom: 2.px),
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(8.px),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9.px, horizontal: 10.px),
          decoration: BoxDecoration(
            color: isActive ? TruDealsColors.sageDeep : Colors.transparent,
            borderRadius: BorderRadius.circular(8.px),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17.px,
                color: isActive ? Colors.white : const Color(0xFFC9CDC8),
              ),
              SizedBox(width: 10.px),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.px,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFFC9CDC8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserSwitcher extends StatefulWidget {
  const _UserSwitcher();

  @override
  State<_UserSwitcher> createState() => _UserSwitcherState();
}

class _UserSwitcherState extends State<_UserSwitcher> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) return const SizedBox.shrink();
        return Container(
          margin: EdgeInsets.only(top: 18.px),
          padding: EdgeInsets.symmetric(horizontal: 10.px),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIGNED IN AS',
                style: TextStyle(
                  fontSize: 10.5.px,
                  letterSpacing: 0.12.px,
                  color: const Color(0xFF9AA39A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5.px),
              PopupMenuButton<String>(
                onSelected: (userId) async {
                  final pass = await _showPasswordDialog(context);
                  if (pass != null) {
                    if (context.mounted) {
                      // Login logic
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'u-joe', child: Text('Joe Farmer')),
                  const PopupMenuItem(value: 'u-sam', child: Text('Sam Rivera')),
                  const PopupMenuItem(value: 'u-dana', child: Text('Dana Okafor')),
                ],
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8.px, horizontal: 9.px),
                  decoration: BoxDecoration(
                    color: TruDealsColors.charcoalSoft,
                    border: Border.all(color: Colors.white.withAlpha(38)),
                    borderRadius: BorderRadius.circular(8.px),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state.user.name,
                        style: TextStyle(color: Colors.white, fontSize: 13.px),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 7.px),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.px, vertical: 3.px),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(99.px),
                ),
                child: Text(
                  '${state.user.role.name.toUpperCase()} · ${state.user.dept.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 10.5.px,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFCFE0CD),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _showPasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter password'),
        content: TextField(controller: controller, obscureText: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Login')),
        ],
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withAlpha(46)),
            foregroundColor: const Color(0xFFC9CDC8),
            minimumSize: Size(double.infinity, 34.px),
            textStyle: TextStyle(fontSize: 12.5.px, fontWeight: FontWeight.w500),
          ),
          child: const Text('Export data'),
        ),
        SizedBox(height: 8.px),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withAlpha(46)),
            foregroundColor: const Color(0xFFC9CDC8),
            minimumSize: Size(double.infinity, 34.px),
            textStyle: TextStyle(fontSize: 12.5.px, fontWeight: FontWeight.w500),
          ),
          child: const Text('Import data'),
        ),
        SizedBox(height: 12.px),
        Text(
          'Data saves in this app automatically.',
          style: TextStyle(
            fontSize: 11.px,
            color: const Color(0xFF8A918A),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
