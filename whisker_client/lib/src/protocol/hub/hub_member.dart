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

/// Keanggotaan Hub; MVP hanya `owner`, `editor`/`viewer` disiapkan.
abstract class HubMember
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  HubMember._({
    this.id,
    required this.hubId,
    required this.userId,
    required this.role,
  });

  factory HubMember({
    int? id,
    required int hubId,
    required _isc.UuidValue userId,
    required String role,
  }) = _HubMemberImpl;

  factory HubMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return HubMember(
      id: jsonSerialization['id'] as int?,
      hubId: jsonSerialization['hubId'] as int,
      userId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      role: jsonSerialization['role'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int hubId;

  _isc.UuidValue userId;

  String role;

  /// Returns a shallow copy of this [HubMember]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  HubMember copyWith({
    int? id,
    int? hubId,
    _isc.UuidValue? userId,
    String? role,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'HubMember',
      if (id != null) 'id': id,
      'hubId': hubId,
      'userId': userId.toJson(),
      'role': role,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'HubMember',
      if (id != null) 'id': id,
      'hubId': hubId,
      'userId': userId.toJson(),
      'role': role,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _HubMemberImpl extends HubMember {
  _HubMemberImpl({
    int? id,
    required int hubId,
    required _isc.UuidValue userId,
    required String role,
  }) : super._(
         id: id,
         hubId: hubId,
         userId: userId,
         role: role,
       );

  /// Returns a shallow copy of this [HubMember]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  HubMember copyWith({
    Object? id = _Undefined,
    int? hubId,
    _isc.UuidValue? userId,
    String? role,
  }) {
    return HubMember(
      id: id is int? ? id : this.id,
      hubId: hubId ?? this.hubId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
    );
  }
}
