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

abstract class CommitResult
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CommitResult._({
    required this.status,
    this.newSha,
    this.latestContent,
    this.latestSha,
    this.reason,
  });

  factory CommitResult({
    required String status,
    String? newSha,
    String? latestContent,
    String? latestSha,
    String? reason,
  }) = _CommitResultImpl;

  factory CommitResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return CommitResult(
      status: jsonSerialization['status'] as String,
      newSha: jsonSerialization['newSha'] as String?,
      latestContent: jsonSerialization['latestContent'] as String?,
      latestSha: jsonSerialization['latestSha'] as String?,
      reason: jsonSerialization['reason'] as String?,
    );
  }

  String status;

  String? newSha;

  String? latestContent;

  String? latestSha;

  String? reason;

  /// Returns a shallow copy of this [CommitResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CommitResult copyWith({
    String? status,
    String? newSha,
    String? latestContent,
    String? latestSha,
    String? reason,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CommitResult',
      'status': status,
      if (newSha != null) 'newSha': newSha,
      if (latestContent != null) 'latestContent': latestContent,
      if (latestSha != null) 'latestSha': latestSha,
      if (reason != null) 'reason': reason,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CommitResult',
      'status': status,
      if (newSha != null) 'newSha': newSha,
      if (latestContent != null) 'latestContent': latestContent,
      if (latestSha != null) 'latestSha': latestSha,
      if (reason != null) 'reason': reason,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CommitResultImpl extends CommitResult {
  _CommitResultImpl({
    required String status,
    String? newSha,
    String? latestContent,
    String? latestSha,
    String? reason,
  }) : super._(
         status: status,
         newSha: newSha,
         latestContent: latestContent,
         latestSha: latestSha,
         reason: reason,
       );

  /// Returns a shallow copy of this [CommitResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CommitResult copyWith({
    String? status,
    Object? newSha = _Undefined,
    Object? latestContent = _Undefined,
    Object? latestSha = _Undefined,
    Object? reason = _Undefined,
  }) {
    return CommitResult(
      status: status ?? this.status,
      newSha: newSha is String? ? newSha : this.newSha,
      latestContent: latestContent is String?
          ? latestContent
          : this.latestContent,
      latestSha: latestSha is String? ? latestSha : this.latestSha,
      reason: reason is String? ? reason : this.reason,
    );
  }
}
