import 'dart:async';
import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart' hide ResponseDecoder;
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:flutter/foundation.dart';
import 'network_client.dart';
import 'network_typedefs.dart';
import 'network_exception.dart';
import 'mock_data.dart';

class MockNetworkClient implements NetworkClient {
  static const _delay = Duration(milliseconds: 300);

  @override
  Future<NetworkResult<T>> get<T>({
    required String path,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) async {
    try {
      debugPrint('Mock GET: $path');
      await Future.delayed(_delay);
      
      // Auth
      if (path == '/api/auth/me') {
        final setBox = Hive.box(MockData.settingsBox);
        final userId = setBox.get('currentUserId');
        if (userId == null) {
          debugPrint('Mock GET /api/auth/me: No currentUserId');
          return Left(const UnauthorisedException(message: 'Not logged in'));
        }
        
        final userBox = Hive.box(MockData.usersBox);
        final data = userBox.get(userId);
        if (data == null) return Left(const UnauthorisedException(message: 'User missing'));
        
        final json = Map<String, dynamic>.from(data as Map);
        return Right(decoder != null ? decoder(json) : json as T);
      }

      if (path == '/api/users') {
        final box = Hive.box(MockData.usersBox);
        final items = box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        return Right(decoder != null ? decoder(items) : items as T);
      }

      // Contacts
      if (path == '/api/contacts') {
        final box = Hive.box(MockData.contactsBox);
        var contacts = box.values
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((c) => c['deleted'] != true)
            .toList();
        
        final stage = queryParameters?['stage'];
        if (stage != null && stage != '') {
          contacts = contacts.where((c) => c['stage'] == stage).toList();
        }
        
        final q = queryParameters?['q']?.toString().toLowerCase();
        if (q != null && q != '') {
          contacts = contacts.where((c) {
            final name = c['name']?.toString().toLowerCase() ?? '';
            final addr = c['property_address']?.toString().toLowerCase() ?? '';
            return name.contains(q) || addr.contains(q);
          }).toList();
        }

        return Right(decoder != null ? decoder(contacts) : contacts as T);
      }

      if (path.startsWith('/api/contacts/')) {
        final segments = path.split('/');
        final id = segments[3];
        
        final box = Hive.box(MockData.contactsBox);
        final rawContact = box.get(id);
        if (rawContact == null) return Left(const BadRequestException(message: 'Contact not found'));
        final contact = Map<String, dynamic>.from(rawContact as Map);

        if (segments.length == 4) {
          return Right(decoder != null ? decoder(contact) : contact as T);
        }
        
        final subPath = segments[4];
        if (subPath == 'activities') {
          final items = List.from(contact['activities'] ?? []);
          return Right(decoder != null ? decoder(items) : items as T);
        }
        if (subPath == 'comms') {
          final items = List.from(contact['comms'] ?? []);
          return Right(decoder != null ? decoder(items) : items as T);
        }
        if (subPath == 'orders') {
          final items = Map.from(contact['orders'] ?? {});
          return Right(decoder != null ? decoder(items) : items as T);
        }
      }

      // Stages
      if (path == '/api/stages') {
        final box = Hive.box(MockData.stagesBox);
        final items = box.values
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
          ..sort((a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int));
        return Right(decoder != null ? decoder(items) : items as T);
      }

      // Dashboard
      if (path == '/api/dashboard/stats') {
        final box = Hive.box(MockData.contactsBox);
        final contacts = box.values.map((e) => Map<String, dynamic>.from(e as Map)).where((c) => c['deleted'] != true).toList();
        final stats = {
          'total_leads': contacts.length,
          'new_leads': contacts.where((c) => c['stage'] == 'new').length,
          'active_deals': contacts.where((c) => !['closed'].contains(c['stage'])).length,
          'pipeline_value': contacts.fold(0.0, (sum, c) => sum + (c['dealValue'] ?? 0.0)),
        };
        return Right(decoder != null ? decoder(stats) : stats as T);
      }

      if (path == '/api/dashboard/today') {
        final box = Hive.box(MockData.contactsBox);
        final now = DateTime.now();
        final items = [];
        for (var rawC in box.values) {
          final c = Map<String, dynamic>.from(rawC as Map);
          for (var rawCb in (c['callbacks'] ?? [])) {
            final cb = Map<String, dynamic>.from(rawCb as Map);
            final when = DateTime.parse(cb['when']);
            if (when.day == now.day && when.month == now.month && when.year == now.year) {
              items.add({
                'id': cb['id'],
                'contact_id': c['id'],
                'contact_name': c['name'],
                'scheduled_at': cb['when'],
                'note': cb['note']
              });
            }
          }
        }
        return Right(decoder != null ? decoder(items) : items as T);
      }

      // Templates
      if (path == '/api/templates') {
        final box = Hive.box(MockData.templatesBox);
        final data = {
          'email': box.get('email'),
          'sms': box.get('sms'),
        };
        return Right(decoder != null ? decoder(data) : data as T);
      }

      // Workflows
      if (path == '/api/workflows') {
        final box = Hive.box(MockData.workflowsBox);
        final items = box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        return Right(decoder != null ? decoder(items) : items as T);
      }

      if (path == '/api/trash') {
        final box = Hive.box(MockData.contactsBox);
        final items = box.values
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((c) => c['deleted'] == true)
            .toList();
        return Right(decoder != null ? decoder(items) : items as T);
      }

      return Left(const BadRequestException(message: 'Not implemented'));
    } catch (e, stack) {
      debugPrint('Mock GET Error: $e\n$stack');
      return Left(UnknownNetworkException(message: e.toString()));
    }
  }

  @override
  Future<NetworkResult<T>> post<T>({
    required String path,
    Object? data,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) async {
    try {
      debugPrint('Mock POST: $path');
      await Future.delayed(_delay);
      
      if (path == '/api/auth/login') {
        final input = Map<String, dynamic>.from(data as Map);
        final email = input['email'];
        final pass = input['password'];
        
        final userBox = Hive.box(MockData.usersBox);
        final userList = userBox.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        final userData = userList.firstWhere(
          (u) => u['email'] == email && u['password'] == pass,
          orElse: () => <String, dynamic>{},
        );
        
        if (userData.isNotEmpty) {
          final setBox = Hive.box(MockData.settingsBox);
          await setBox.put('currentUserId', userData['id']);
          return Right(decoder != null ? decoder(userData) : userData as T);
        }
        return Left(const UnauthorisedException(message: 'Invalid credentials'));
      }

      if (path == '/api/contacts') {
        final json = Map<String, dynamic>.from(data as Map);
        final box = Hive.box(MockData.contactsBox);
        final id = 'c-${DateTime.now().millisecondsSinceEpoch}';
        final contact = {
          ...json,
          'id': id,
          'createdAt': DateTime.now().toIso8601String(),
          'deleted': false,
          'activities': [{'ts': DateTime.now().toIso8601String(), 'type': 'Note', 'text': 'Profile created', 'by': 'system'}],
          'callbacks': [],
          'comms': [],
          'enrollments': [],
          'orders': {},
          'tags': json['tags'] ?? [],
        };
        await box.put(id, contact);
        return Right(decoder != null ? decoder(contact) : contact as T);
      }

      if (path.startsWith('/api/contacts/') && path.endsWith('/stage')) {
        final id = path.split('/')[3];
        final json = Map<String, dynamic>.from(data as Map);
        final box = Hive.box(MockData.contactsBox);
        final contact = Map<String, dynamic>.from(box.get(id) as Map);
        final oldStage = contact['stage'];
        contact['stage'] = json['stage'];
        contact['activities'] = [...(contact['activities'] ?? []), {
          'ts': DateTime.now().toIso8601String(),
          'type': 'Stage',
          'text': 'Moved from $oldStage to ${json['stage']}',
          'by': 'system'
        }];
        await box.put(id, contact);
        return Right(decoder != null ? decoder(contact) : contact as T);
      }

      if (path.endsWith('/restore')) {
        final id = path.split('/')[3];
        final box = Hive.box(MockData.contactsBox);
        final contact = Map<String, dynamic>.from(box.get(id) as Map);
        contact['deleted'] = false;
        contact['activities'] = [...(contact['activities'] ?? []), {
          'ts': DateTime.now().toIso8601String(),
          'type': 'Restore',
          'text': 'Profile restored from Trash',
          'by': 'system'
        }];
        await box.put(id, contact);
        return Right(null as T);
      }

      if (path == '/api/stages') {
        final json = Map<String, dynamic>.from(data as Map);
        final box = Hive.box(MockData.stagesBox);
        await box.put(json['key'], json);
        return Right(decoder != null ? decoder(json) : json as T);
      }

      if (path == '/api/users') {
        final json = Map<String, dynamic>.from(data as Map);
        final box = Hive.box(MockData.usersBox);
        await box.put(json['id'], json);
        return Right(decoder != null ? decoder(json) : json as T);
      }

      return Left(const BadRequestException(message: 'Not implemented'));
    } catch (e, stack) {
      debugPrint('Mock POST Error: $e\n$stack');
      return Left(UnknownNetworkException(message: e.toString()));
    }
  }

  @override
  Future<NetworkResult<T>> patch<T>({
    required String path,
    Object? data,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) async {
    try {
      debugPrint('Mock PATCH: $path');
      await Future.delayed(_delay);
      
      if (path.startsWith('/api/contacts/')) {
        final id = path.split('/').last;
        final json = Map<String, dynamic>.from(data as Map);
        final box = Hive.box(MockData.contactsBox);
        final contact = Map<String, dynamic>.from(box.get(id) as Map);
        
        json.forEach((key, value) {
          contact[key] = value;
        });
        
        await box.put(id, contact);
        return Right(decoder != null ? decoder(contact) : contact as T);
      }

      if (path == '/api/auth/me') {
        final json = Map<String, dynamic>.from(data as Map);
        final setBox = Hive.box(MockData.settingsBox);
        final userId = setBox.get('currentUserId');
        final userBox = Hive.box(MockData.usersBox);
        final user = Map<String, dynamic>.from(userBox.get(userId) as Map);
        
        json.forEach((key, value) => user[key] = value);
        await userBox.put(userId, user);
        return Right(decoder != null ? decoder(user) : user as T);
      }

      if (path.startsWith('/api/workflows/')) {
        final id = path.split('/').last;
        final json = Map<String, dynamic>.from(data as Map);
        final box = Hive.box(MockData.workflowsBox);
        final wf = Map<String, dynamic>.from(box.get(id) as Map);
        json.forEach((key, value) => wf[key] = value);
        await box.put(id, wf);
        return Right(decoder != null ? decoder(wf) : wf as T);
      }

      return Left(const BadRequestException(message: 'Not implemented'));
    } catch (e, stack) {
      debugPrint('Mock PATCH Error: $e\n$stack');
      return Left(UnknownNetworkException(message: e.toString()));
    }
  }

  @override
  Future<NetworkResult<T>> put<T>({
    required String path,
    Object? data,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) async {
    await Future.delayed(_delay);
    return Left(const BadRequestException(message: 'Not implemented'));
  }

  @override
  Future<NetworkResult<T>> delete<T>({
    required String path,
    Object? data,
    Json? queryParameters,
    Json? headers,
    ResponseDecoder<T>? decoder,
    CancelToken? cancelToken,
  }) async {
    try {
      debugPrint('Mock DELETE: $path');
      await Future.delayed(_delay);

      if (path.startsWith('/api/contacts/')) {
        final id = path.split('/').last;
        final box = Hive.box(MockData.contactsBox);
        final contact = Map<String, dynamic>.from(box.get(id) as Map);
        contact['deleted'] = true;
        contact['deletedAt'] = DateTime.now().toIso8601String();
        await box.put(id, contact);
        return Right(null as T);
      }

      if (path.startsWith('/api/stages/')) {
        final key = path.split('/').last;
        final box = Hive.box(MockData.stagesBox);
        await box.delete(key);
        return Right(null as T);
      }

      return Left(const BadRequestException(message: 'Not implemented'));
    } catch (e, stack) {
      debugPrint('Mock DELETE Error: $e\n$stack');
      return Left(UnknownNetworkException(message: e.toString()));
    }
  }

  @override
  void close({bool force = false}) {}
}
