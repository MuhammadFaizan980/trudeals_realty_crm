import '../../../../core/network/network_typedefs.dart';

abstract interface class AdminRepository {
  /// Full JSON export of the workspace (`super` only) — same shape the
  /// prototype's own "Export data" button produces.
  Future<NetworkResult<Map<String, dynamic>>> exportData();

  /// One-time (but safe to re-run) import of a previously exported backup
  /// (`super` only). Returns the server's per-collection import counts.
  Future<NetworkResult<Map<String, dynamic>>> importData(Map<String, dynamic> data);
}
