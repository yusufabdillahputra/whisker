/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// Catatan satu backup zip harian.
abstract class BackupRecord
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BackupRecord._({
    this.id,
    required this.hubId,
    required this.objectKey,
    required this.sizeBytes,
    required this.createdAt,
    required this.status,
    this.error,
  });

  factory BackupRecord({
    int? id,
    required int hubId,
    required String objectKey,
    required int sizeBytes,
    required DateTime createdAt,
    required String status,
    String? error,
  }) = _BackupRecordImpl;

  factory BackupRecord.fromJson(Map<String, dynamic> jsonSerialization) {
    return BackupRecord(
      id: jsonSerialization['id'] as int?,
      hubId: jsonSerialization['hubId'] as int,
      objectKey: jsonSerialization['objectKey'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      status: jsonSerialization['status'] as String,
      error: jsonSerialization['error'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int hubId;

  String objectKey;

  int sizeBytes;

  DateTime createdAt;

  String status;

  String? error;

  /// Returns a shallow copy of this [BackupRecord]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BackupRecord copyWith({
    int? id,
    int? hubId,
    String? objectKey,
    int? sizeBytes,
    DateTime? createdAt,
    String? status,
    String? error,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BackupRecord',
      if (id != null) 'id': id,
      'hubId': hubId,
      'objectKey': objectKey,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toJson(),
      'status': status,
      if (error != null) 'error': error,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BackupRecord',
      if (id != null) 'id': id,
      'hubId': hubId,
      'objectKey': objectKey,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toJson(),
      'status': status,
      if (error != null) 'error': error,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BackupRecordImpl extends BackupRecord {
  _BackupRecordImpl({
    int? id,
    required int hubId,
    required String objectKey,
    required int sizeBytes,
    required DateTime createdAt,
    required String status,
    String? error,
  }) : super._(
         id: id,
         hubId: hubId,
         objectKey: objectKey,
         sizeBytes: sizeBytes,
         createdAt: createdAt,
         status: status,
         error: error,
       );

  /// Returns a shallow copy of this [BackupRecord]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BackupRecord copyWith({
    Object? id = _Undefined,
    int? hubId,
    String? objectKey,
    int? sizeBytes,
    DateTime? createdAt,
    String? status,
    Object? error = _Undefined,
  }) {
    return BackupRecord(
      id: id is int? ? id : this.id,
      hubId: hubId ?? this.hubId,
      objectKey: objectKey ?? this.objectKey,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      error: error is String? ? error : this.error,
    );
  }
}
