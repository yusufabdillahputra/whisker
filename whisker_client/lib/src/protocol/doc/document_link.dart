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

/// Wikilink dari satu dokumen ke target (path/nama), resolusi opsional.
abstract class DocumentLink
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DocumentLink._({
    this.id,
    required this.fromDocId,
    required this.hubId,
    required this.toPath,
    this.toDocId,
  });

  factory DocumentLink({
    int? id,
    required int fromDocId,
    required int hubId,
    required String toPath,
    int? toDocId,
  }) = _DocumentLinkImpl;

  factory DocumentLink.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocumentLink(
      id: jsonSerialization['id'] as int?,
      fromDocId: jsonSerialization['fromDocId'] as int,
      hubId: jsonSerialization['hubId'] as int,
      toPath: jsonSerialization['toPath'] as String,
      toDocId: jsonSerialization['toDocId'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int fromDocId;

  int hubId;

  String toPath;

  int? toDocId;

  /// Returns a shallow copy of this [DocumentLink]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DocumentLink copyWith({
    int? id,
    int? fromDocId,
    int? hubId,
    String? toPath,
    int? toDocId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocumentLink',
      if (id != null) 'id': id,
      'fromDocId': fromDocId,
      'hubId': hubId,
      'toPath': toPath,
      if (toDocId != null) 'toDocId': toDocId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocumentLink',
      if (id != null) 'id': id,
      'fromDocId': fromDocId,
      'hubId': hubId,
      'toPath': toPath,
      if (toDocId != null) 'toDocId': toDocId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentLinkImpl extends DocumentLink {
  _DocumentLinkImpl({
    int? id,
    required int fromDocId,
    required int hubId,
    required String toPath,
    int? toDocId,
  }) : super._(
         id: id,
         fromDocId: fromDocId,
         hubId: hubId,
         toPath: toPath,
         toDocId: toDocId,
       );

  /// Returns a shallow copy of this [DocumentLink]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DocumentLink copyWith({
    Object? id = _Undefined,
    int? fromDocId,
    int? hubId,
    String? toPath,
    Object? toDocId = _Undefined,
  }) {
    return DocumentLink(
      id: id is int? ? id : this.id,
      fromDocId: fromDocId ?? this.fromDocId,
      hubId: hubId ?? this.hubId,
      toPath: toPath ?? this.toPath,
      toDocId: toDocId is int? ? toDocId : this.toDocId,
    );
  }
}
