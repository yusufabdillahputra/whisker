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

abstract class DocContent
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DocContent._({
    required this.path,
    required this.content,
    required this.blobSha,
    this.baseSha,
    this.readOnlyReason,
  });

  factory DocContent({
    required String path,
    required String content,
    required String blobSha,
    String? baseSha,
    String? readOnlyReason,
  }) = _DocContentImpl;

  factory DocContent.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocContent(
      path: jsonSerialization['path'] as String,
      content: jsonSerialization['content'] as String,
      blobSha: jsonSerialization['blobSha'] as String,
      baseSha: jsonSerialization['baseSha'] as String?,
      readOnlyReason: jsonSerialization['readOnlyReason'] as String?,
    );
  }

  String path;

  String content;

  String blobSha;

  String? baseSha;

  String? readOnlyReason;

  /// Returns a shallow copy of this [DocContent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DocContent copyWith({
    String? path,
    String? content,
    String? blobSha,
    String? baseSha,
    String? readOnlyReason,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocContent',
      'path': path,
      'content': content,
      'blobSha': blobSha,
      if (baseSha != null) 'baseSha': baseSha,
      if (readOnlyReason != null) 'readOnlyReason': readOnlyReason,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocContent',
      'path': path,
      'content': content,
      'blobSha': blobSha,
      if (baseSha != null) 'baseSha': baseSha,
      if (readOnlyReason != null) 'readOnlyReason': readOnlyReason,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocContentImpl extends DocContent {
  _DocContentImpl({
    required String path,
    required String content,
    required String blobSha,
    String? baseSha,
    String? readOnlyReason,
  }) : super._(
         path: path,
         content: content,
         blobSha: blobSha,
         baseSha: baseSha,
         readOnlyReason: readOnlyReason,
       );

  /// Returns a shallow copy of this [DocContent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DocContent copyWith({
    String? path,
    String? content,
    String? blobSha,
    Object? baseSha = _Undefined,
    Object? readOnlyReason = _Undefined,
  }) {
    return DocContent(
      path: path ?? this.path,
      content: content ?? this.content,
      blobSha: blobSha ?? this.blobSha,
      baseSha: baseSha is String? ? baseSha : this.baseSha,
      readOnlyReason: readOnlyReason is String?
          ? readOnlyReason
          : this.readOnlyReason,
    );
  }
}
