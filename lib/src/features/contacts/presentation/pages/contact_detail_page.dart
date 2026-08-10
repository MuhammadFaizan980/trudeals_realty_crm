import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:trudeals_realty_crm/src/core/di/injection.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/contact.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/activity.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/communication.dart';
import 'package:trudeals_realty_crm/src/features/contacts/domain/entities/vendor_order.dart';
import 'package:trudeals_realty_crm/src/features/contacts/presentation/cubits/contact_detail_cubit.dart';

class ContactDetailPage extends StatelessWidget {
  final String contactId;
  const ContactDetailPage({super.key, required this.contactId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ContactDetailCubit>()..loadContact(contactId),
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<ContactDetailCubit, ContactDetailState>(
            builder: (context, state) => Text(state.contact?.name ?? 'Loading...'),
          ),
          backgroundColor: Colors.blueGrey[50],
        ),
        body: const _ContactDetailView(),
      ),
    );
  }
}

class _ContactDetailView extends StatelessWidget {
  const _ContactDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContactDetailCubit, ContactDetailState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null) {
          return Center(child: Text(state.errorMessage!));
        }
        if (state.contact == null) {
          return const Center(child: Text('Contact not found'));
        }

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              _HeaderSection(contact: state.contact!),
              const TabBar(
                tabs: [
                  Tab(text: 'Timeline'),
                  Tab(text: 'Comms'),
                  Tab(text: 'Orders'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _TimelineTab(activities: state.activities),
                    _CommsTab(communications: state.communications),
                    _OrdersTab(orders: state.orders),
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

class _HeaderSection extends StatelessWidget {
  final Contact contact;
  const _HeaderSection({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.px),
      color: Colors.blueGrey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30.px,
                child: Text(contact.name[0], style: TextStyle(fontSize: 24.px)),
              ),
              SizedBox(width: 16.px),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: TextStyle(fontSize: 20.px, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      contact.propertyAddress ?? 'No address',
                      style: TextStyle(fontSize: 14.px, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.px),
          Wrap(
            spacing: 8.px,
            children: [
              _InfoChip(label: contact.stage.toUpperCase()),
              _InfoChip(label: contact.priority.name.toUpperCase()),
              _InfoChip(label: '\$${contact.dealValue.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 10.px)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final List<Activity> activities;
  const _TimelineTab({required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Center(child: Text('No activity recorded'));
    }
    return ListView.separated(
      padding: EdgeInsets.all(16.px),
      itemCount: activities.length,
      separatorBuilder: (context, index) => Divider(height: 24.px),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12.px,
                  height: 12.px,
                  decoration: const BoxDecoration(
                    color: Colors.blueGrey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            SizedBox(width: 16.px),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        activity.type,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.px),
                      ),
                      Text(
                        DateFormat('MMM d, h:mm a').format(activity.timestamp),
                        style: TextStyle(fontSize: 11.px, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.px),
                  Text(activity.text, style: TextStyle(fontSize: 13.px)),
                  if (activity.by != null) ...[
                    SizedBox(height: 2.px),
                    Text(
                      'by ${activity.by}',
                      style: TextStyle(fontSize: 11.px, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommsTab extends StatelessWidget {
  final List<Communication> communications;
  const _CommsTab({required this.communications});

  @override
  Widget build(BuildContext context) {
    if (communications.isEmpty) {
      return const Center(child: Text('No messages found'));
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.px),
      itemCount: communications.length,
      itemBuilder: (context, index) {
        final comm = communications[index];
        final isOutbound = comm.direction == CommDirection.outbound;
        return Align(
          alignment: isOutbound ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(bottom: 12.px),
            padding: EdgeInsets.all(12.px),
            decoration: BoxDecoration(
              color: isOutbound ? Colors.blueGrey[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8.px),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      comm.channel == CommChannel.email ? Icons.email : Icons.sms,
                      size: 12.px,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4.px),
                    Text(
                      DateFormat('MMM d, h:mm a').format(comm.timestamp),
                      style: TextStyle(fontSize: 10.px, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (comm.subject != null) ...[
                  SizedBox(height: 4.px),
                  Text(
                    comm.subject!,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.px),
                  ),
                ],
                SizedBox(height: 4.px),
                Text(comm.body, style: TextStyle(fontSize: 13.px)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrdersTab extends StatelessWidget {
  final List<VendorOrder> orders;
  const _OrdersTab({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('No vendor orders'));
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.px),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.camera_alt, // Simplified for now
              color: Colors.blueGrey,
            ),
            title: const Text('ORDER'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vendor: ${order.company ?? 'TBD'}'),
                Text('Ordered: ${DateFormat('MMM d').format(order.orderedAt)}'),
                if (order.eta != null)
                  Text(
                    'ETA: ${DateFormat('MMM d').format(order.eta!)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
