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
import 'package:serverpod/serverpod.dart' as _is;

abstract class CommitRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CommitRequest._({
    required this.hubId,
    required this.path,
    required this.content,
    required this.message,
    this.description,
    this.baseSha,
  });

  factory CommitRequest({
    required int hubId,
    required String path,
    required String content,
    required String message,
    String? description,
    String? baseSha,
  }) = _CommitRequestImpl;

  factory CommitRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return CommitRequest(
      hubId: jsonSerialization['hubId'] as int,
      path: jsonSerialization['path'] as String,
      content: jsonSerialization['content'] as String,
      message: jsonSerialization['message'] as String,
      description: jsonSerialization['description'] as String?,
      baseSha: jsonSerialization['baseSha'] as String?,
    );
  }

  int hubId;

  String path;

  String content;

  String message;

  String? description;

  String? baseSha;

  /// Returns a shallow copy of this [CommitRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CommitRequest copyWith({
    int? hubId,
    String? path,
    String? content,
    String? message,
    String? description,
    String? baseSha,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CommitRequest',
      'hubId': hubId,
      'path': path,
      'content': content,
      'message': message,
      if (description != null) 'description': description,
      if (baseSha != null) 'baseSha': baseSha,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CommitRequest',
      'hubId': hubId,
      'path': path,
      'content': content,
      'message': message,
      if (description != null) 'description': description,
      if (baseSha != null) 'baseSha': baseSha,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CommitRequestImpl extends CommitRequest {
  _CommitRequestImpl({
    required int hubId,
    required String path,
    required String content,
    required String message,
    String? description,
    String? baseSha,
  }) : super._(
         hubId: hubId,
         path: path,
         content: content,
         message: message,
         description: description,
         baseSha: baseSha,
       );

  /// Returns a shallow copy of this [CommitRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CommitRequest copyWith({
    int? hubId,
    String? path,
    String? content,
    String? message,
    Object? description = _Undefined,
    Object? baseSha = _Undefined,
  }) {
    return CommitRequest(
      hubId: hubId ?? this.hubId,
      path: path ?? this.path,
      content: content ?? this.content,
      message: message ?? this.message,
      description: description is String? ? description : this.description,
      baseSha: baseSha is String? ? baseSha : this.baseSha,
    );
  }
}
