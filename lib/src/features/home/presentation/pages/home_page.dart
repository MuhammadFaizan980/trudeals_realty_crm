import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:trudeals_realty_crm/src/features/home/presentation/widgets/trudeals_sidebar.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/pages/pipeline_page.dart';
import 'package:trudeals_realty_crm/src/features/calendar/presentation/pages/calendar_page.dart';
import 'package:trudeals_realty_crm/src/features/automations/presentation/pages/workflow_list_page.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/pages/contacts_page.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/pages/intake_forms_page.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/pages/trash_page.dart';
import 'package:trudeals_realty_crm/src/features/settings/presentation/pages/settings_page.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/widgets/contact_drawer.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/pages/add_contact_page.dart';
import 'package:trudeals_realty_crm/src/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:trudeals_realty_crm/src/features/auth/domain/entities/user.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? _selectedContactId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'Dashboard',
    'Calendar',
    'Pipeline',
    'Contacts',
    'Marketing Automations',
    'Intake Forms',
    'Trash',
    'Settings',
  ];

  final List<Widget> _pages = [
    const DashboardPage(),
    const CalendarPage(),
    const PipelinePage(),
    const ContactsPage(),
    const WorkflowListPage(),
    const IntakeFormsPage(),
    const TrashPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isLargeScreen ? _MobileDrawer(
        currentIndex: _currentIndex,
        onIndexChanged: (index) {
          setState(() => _currentIndex = index);
          Navigator.pop(context);
        },
      ) : null,
      endDrawer: _selectedContactId != null 
          ? ContactDrawer(contactId: _selectedContactId!) 
          : _NotificationsDrawer(),
      onEndDrawerChanged: (isOpen) {
        if (!isOpen) setState(() => _selectedContactId = null);
      },
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (isLargeScreen)
              TruDealsSidebar(
                currentIndex: _currentIndex,
                onIndexChanged: (index) => setState(() => _currentIndex = index),
              ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: _titles[_currentIndex],
                    onMenuTap: !isLargeScreen ? () => _scaffoldKey.currentState?.openDrawer() : null,
                    onAddTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddContactPage()));
                    },
                    onNotificationsTap: () {
                      setState(() => _selectedContactId = null);
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: _pages,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !isLargeScreen
          ? BottomNavigationBar(
              currentIndex: _currentIndex >= 4 ? 4 : _currentIndex,
              onTap: (index) {
                if (index == 4) {
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  setState(() => _currentIndex = index);
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dash'),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Cal'),
                BottomNavigationBarItem(icon: Icon(Icons.view_kanban), label: 'Pipe'),
                BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Leads'),
                BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
              ],
            )
          : null,
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuTap;
  final VoidCallback onAddTap;
  final VoidCallback onNotificationsTap;

  const _TopBar({
    required this.title,
    this.onMenuTap,
    required this.onAddTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.px, 20.px, 20.px, 12.px),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (onMenuTap != null)
                  IconButton(
                    icon: const Icon(Icons.menu), 
                    onPressed: onMenuTap,
                    padding: EdgeInsets.zero,
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24.px),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: onNotificationsTap,
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.px),
                    side: const BorderSide(color: Color(0xFFE0DFD8)),
                  ),
                ),
              ),
              SizedBox(width: 10.px),
              ElevatedButton(
                onPressed: onAddTap,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12.px, vertical: 8.px),
                  minimumSize: Size.zero,
                ),
                child: Text('+ New', style: TextStyle(fontSize: 13.px)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationsDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320.px,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(20.px),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifications', style: TextStyle(fontSize: 18.px, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(10.px),
                children: const [
                  ListTile(
                    leading: CircleAvatar(backgroundColor: Color(0xFFF4F3EE), child: Icon(Icons.person_add, size: 16)),
                    title: Text('New Lead: Maria Delgado'),
                    subtitle: Text('Added via Postcard · 2h ago'),
                  ),
                  ListTile(
                    leading: CircleAvatar(backgroundColor: Color(0xFFF4F3EE), child: Icon(Icons.calendar_today, size: 16)),
                    title: Text('Reminder: Call Robert Chen'),
                    subtitle: Text('Due in 15 mins'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  const _MobileDrawer({required this.currentIndex, required this.onIndexChanged});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const DrawerHeader(
              child: Center(child: Text('TruDeals Realty CRM', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Marketing Automations'),
              selected: currentIndex == 4,
              onTap: () => onIndexChanged(4),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('Intake Forms'),
              selected: currentIndex == 5,
              onTap: () => onIndexChanged(5),
            ),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is Authenticated && state.user.role == UserRole.superAdmin) {
                  return ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Trash'),
                    selected: currentIndex == 6,
                    onTap: () => onIndexChanged(6),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              selected: currentIndex == 7,
              onTap: () => onIndexChanged(7),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                context.read<AuthCubit>().logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
