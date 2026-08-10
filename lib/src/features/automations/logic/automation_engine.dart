import 'dart:async';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../../../core/network/mock_data.dart';

class AutomationEngine {
  Timer? _timer;
  bool _isRunning = false;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _tick();
    });
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
  }

  Future<void> _tick() async {
    final contactBox = Hive.box(MockData.contactsBox);
    final workflowBox = Hive.box(MockData.workflowsBox);
    
    for (var contactId in contactBox.keys) {
      final contactData = Map<String, dynamic>.from(contactBox.get(contactId));
      if (contactData['deleted'] == true) continue;
      
      final enrollments = List<Map<String, dynamic>>.from(contactData['enrollments'] ?? []);
      bool changed = false;
      
      for (var i = 0; i < enrollments.length; i++) {
        final enr = enrollments[i];
        if (enr['done'] == true) continue;
        
        final nextAt = DateTime.parse(enr['nextAt']);
        if (nextAt.isAfter(DateTime.now())) continue;
        
        final wf = workflowBox.get(enr['wfId']);
        if (wf == null) {
          enr['done'] = true;
          changed = true;
          continue;
        }
        
        final steps = List<Map<String, dynamic>>.from(wf['steps'] ?? []);
        if (enr['stepIndex'] >= steps.length) {
          enr['done'] = true;
          changed = true;
          continue;
        }
        
        // Advance step
        enr['stepIndex']++;
        if (enr['stepIndex'] >= steps.length) {
          enr['done'] = true;
        } else {
          final nextStep = steps[enr['stepIndex']];
          if (nextStep['type'] == 'wait') {
            final amount = nextStep['amount'] ?? 10;
            final unit = nextStep['unit'] ?? 'min';
            final duration = switch(unit) {
              'min' => Duration(minutes: amount),
              'hour' => Duration(hours: amount),
              'day' => Duration(days: amount),
              _ => const Duration(minutes: 10),
            };
            enr['nextAt'] = DateTime.now().add(duration).toIso8601String();
          } else {
            enr['nextAt'] = DateTime.now().toIso8601String();
          }
        }
        changed = true;
      }
      
      if (changed) {
        contactData['enrollments'] = enrollments;
        await contactBox.put(contactId, contactData);
      }
    }
  }
}
