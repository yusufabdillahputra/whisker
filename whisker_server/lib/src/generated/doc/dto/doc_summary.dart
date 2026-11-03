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

abstract class DocSummary
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DocSummary._({
    required this.path,
    required this.title,
    required this.area,
    this.type,
    this.status,
  });

  factory DocSummary({
    required String path,
    required String title,
    required String area,
    String? type,
    String? status,
  }) = _DocSummaryImpl;

  factory DocSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocSummary(
      path: jsonSerialization['path'] as String,
      title: jsonSerialization['title'] as String,
      area: jsonSerialization['area'] as String,
      type: jsonSerialization['type'] as String?,
      status: jsonSerialization['status'] as String?,
    );
  }

  String path;

  String title;

  String area;

  String? type;

  String? status;

  /// Returns a shallow copy of this [DocSummary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DocSummary copyWith({
    String? path,
    String? title,
    String? area,
    String? type,
    String? status,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocSummary',
      'path': path,
      'title': title,
      'area': area,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocSummary',
      'path': path,
      'title': title,
      'area': area,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocSummaryImpl extends DocSummary {
  _DocSummaryImpl({
    required String path,
    required String title,
    required String area,
    String? type,
    String? status,
  }) : super._(
         path: path,
         title: title,
         area: area,
         type: type,
         status: status,
       );

  /// Returns a shallow copy of this [DocSummary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DocSummary copyWith({
    String? path,
    String? title,
    String? area,
    Object? type = _Undefined,
    Object? status = _Undefined,
  }) {
    return DocSummary(
      path: path ?? this.path,
      title: title ?? this.title,
      area: area ?? this.area,
      type: type is String? ? type : this.type,
      status: status is String? ? status : this.status,
    );
  }
}
