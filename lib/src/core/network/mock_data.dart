import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:intl/intl.dart';

class MockData {
  static const String contactsBox = 'contacts';
  static const String usersBox = 'users';
  static const String stagesBox = 'stages';
  static const String templatesBox = 'templates';
  static const String workflowsBox = 'workflows';
  static const String notificationsBox = 'notifications';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.openBox(contactsBox);
    await Hive.openBox(usersBox);
    await Hive.openBox(stagesBox);
    await Hive.openBox(templatesBox);
    await Hive.openBox(workflowsBox);
    await Hive.openBox(notificationsBox);
    await Hive.openBox(settingsBox);

    final uBox = Hive.box(usersBox);
    if (uBox.isEmpty) await _seedUsers(uBox);

    final sBox = Hive.box(stagesBox);
    if (sBox.isEmpty) await _seedStages(sBox);

    final tBox = Hive.box(templatesBox);
    if (tBox.isEmpty) await _seedTemplates(tBox);

    final wBox = Hive.box(workflowsBox);
    if (wBox.isEmpty) await _seedWorkflows(wBox);

    final cBox = Hive.box(contactsBox);
    if (cBox.isEmpty) await _seedContacts(cBox);

    final setBox = Hive.box(settingsBox);
    if (setBox.isEmpty) await setBox.put('currentUserId', 'u-joe');
  }

  static Future<void> _seedUsers(Box box) async {
    final users = [
      {
        'id': 'u-joe',
        'name': 'Joe Farmer',
        'role': 'super',
        'dept': 'Management',
        'phone': '(407) 555-0101',
        'email': 'joe@trudealsrealty.com',
        'password': 'demo',
        'emailSig': 'Joe Farmer\nBroker/Owner, TruDeals Realty\n(407) 555-0101 · trudealsrealty.com',
        'smsSig': '— Joe, TruDeals Realty'
      },
      {
        'id': 'u-sam',
        'name': 'Sam Rivera',
        'role': 'sales',
        'dept': 'Sales',
        'phone': '(407) 555-0102',
        'email': 'sam@trudealsrealty.com',
        'password': 'demo',
        'emailSig': 'Sam Rivera\nSales, TruDeals Realty\n(407) 555-0102 · trudealsrealty.com',
        'smsSig': '— Sam, TruDeals Realty'
      },
      {
        'id': 'u-dana',
        'name': 'Dana Okafor',
        'role': 'support',
        'dept': 'Customer Support',
        'phone': '(407) 555-0103',
        'email': 'dana@trudealsrealty.com',
        'password': 'demo',
        'emailSig': 'Dana Okafor\nCustomer Support, TruDeals Realty\n(407) 555-0103 · trudealsrealty.com',
        'smsSig': '— Dana, TruDeals Realty'
      }
    ];
    for (var u in users) {
      await box.put(u['id'], u);
    }
  }

  static Future<void> _seedStages(Box box) async {
    final stages = [
      {'key': 'new', 'label': 'New Lead', 'roles': ['super', 'sales'], 'sort_order': 0},
      {'key': 'contacted', 'label': 'Contacted', 'roles': ['super', 'sales'], 'sort_order': 1},
      {'key': 'appt', 'label': 'Listing Appt', 'roles': ['super', 'sales'], 'sort_order': 2},
      {'key': 'signed', 'label': 'Agreement Signed', 'roles': ['super', 'sales'], 'sort_order': 3},
      {'key': 'photos', 'label': 'Order Photos', 'roles': ['super', 'sales'], 'sort_order': 4},
      {'key': 'sign', 'label': 'Order Sign', 'roles': ['super', 'sales'], 'sort_order': 5},
      {'key': 'active', 'label': 'Active Listing', 'roles': ['super', 'sales'], 'sort_order': 6},
      {'key': 'contract', 'label': 'Under Contract', 'roles': ['super', 'sales'], 'sort_order': 7},
      {'key': 'closed', 'label': 'Closed', 'roles': ['super', 'sales'], 'sort_order': 8},
      {'key': 'support', 'label': 'Customer Support', 'roles': ['super', 'support'], 'sort_order': 9}
    ];
    for (var s in stages) {
      await box.put(s['key'], s);
    }
  }

  static Future<void> _seedTemplates(Box box) async {
    final templates = {
      'email': [
        {
          'id': 'tpl-e-listing',
          'name': '0.5% listing email',
          'subject': 'Your home at {{address}} — keep {{savings}} at closing',
          'body':
              'Hi {{first}},\n\nThanks for your interest in TruDeals Realty. On a sale around {{price}}, our 0.5% full-service listing keeps roughly {{savings}} in your pocket versus a traditional 3% listing side — same MLS exposure, same professional service.\n\nWould a quick 15-minute call this week work to walk through it?'
        },
        {
          'id': 'tpl-e-agreement',
          'name': 'Listing agreement sent',
          'subject': 'Your TruDeals listing agreement',
          'body': 'Hi {{first}},\n\nGreat speaking with you today. I\'ve sent over the listing agreement for {{address}}. You can customize the terms before signing.'
        }
      ],
      'sms': [
        {
          'id': 'tpl-s-intro',
          'name': 'Seller intro SMS',
          'body':
              'Hi {{first}}, it\'s TruDeals Realty — thanks for reaching out about {{address}}. Our 0.5% listing could save you about {{savings}} vs. a traditional agent. Watch for our email!'
        }
      ]
    };
    await box.put('email', templates['email']);
    await box.put('sms', templates['sms']);
  }

  static Future<void> _seedWorkflows(Box box) async {
    final workflows = [
      {
        'id': 'wf-seller',
        'name': 'Seller Lead – Florida nurture',
        'active': true,
        'trigger': {'type': 'tag', 'value': 'seller-lead-florida'},
        'steps': [
          {'id': 's1', 'type': 'sms', 'tpl': 'tpl-s-intro'},
          {'id': 's2', 'type': 'wait', 'amount': 10, 'unit': 'min'},
          {'id': 's3', 'type': 'email', 'tpl': 'tpl-e-listing'}
        ]
      }
    ];
    for (var w in workflows) {
      await box.put(w['id'], w);
    }
  }

  static Future<void> _seedContacts(Box box) async {
    final now = DateTime.now();
    String d(int offset) => DateFormat('yyyy-MM-dd').format(now.add(Duration(days: offset)));
    final contacts = [
      {
        'id': 'c-001',
        'name': 'Maria Delgado',
        'phone': '(407) 555-0142',
        'email': 'maria.d@email.com',
        'property_address': '1428 Lakeshore Dr, Orlando, FL',
        'source': 'Postcard',
        'plan': 'full',
        'stage': 'appt',
        'dealValue': 465000.0,
        'followUp': d(1),
        'priority': 'high',
        'assignedTo': 'u-sam',
        'leadType': 'seller',
        'tags': ['seller-lead-florida'],
        'deleted': false,
        'createdAt': now.toIso8601String(),
        'activities': [
          {'ts': now.subtract(const Duration(days: 2)).toIso8601String(), 'type': 'Note', 'text': 'Selling to relocate to Tampa.', 'by': 'u-joe'},
          {'ts': now.subtract(const Duration(days: 1)).toIso8601String(), 'type': 'Call', 'text': 'Walked through 0.5% plan.', 'by': 'u-joe'}
        ],
        'callbacks': [
          {'id': 'cb1', 'when': now.add(const Duration(minutes: 30)).toIso8601String(), 'note': 'Confirm listing appointment details', 'reminders': [15, 10], 'notified': {}}
        ],
        'comms': [],
        'enrollments': [],
        'orders': {}
      },
      {
        'id': 'c-002',
        'name': 'Robert Chen',
        'phone': '(305) 555-0114',
        'email': 'r.chen@email.com',
        'property_address': '2201 Coral Way, Miami, FL',
        'source': 'Referral',
        'plan': 'undecided',
        'stage': 'contacted',
        'dealValue': 380000.0,
        'followUp': d(-1),
        'priority': 'high',
        'assignedTo': 'u-joe',
        'leadType': 'seller',
        'tags': [],
        'deleted': false,
        'createdAt': now.toIso8601String(),
        'activities': [],
        'callbacks': [],
        'comms': [],
        'enrollments': [],
        'orders': {}
      }
    ];
    for (var c in contacts) {
      await box.put(c['id'], c);
    }
  }
}
