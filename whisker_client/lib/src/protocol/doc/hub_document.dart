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
import 'package:whisker_client/src/protocol/protocol.dart' as _iz3sasjg;

/// Indeks satu file markdown di Hub (turunan repo; isi tidak disimpan).
abstract class HubDocument
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  HubDocument._({
    this.id,
    required this.hubId,
    required this.path,
    required this.title,
    required this.area,
    this.type,
    this.status,
    required this.frontmatter,
    required this.tags,
    required this.blobSha,
    this.lastCommitSha,
    required this.updatedAt,
  });

  factory HubDocument({
    int? id,
    required int hubId,
    required String path,
    required String title,
    required String area,
    String? type,
    String? status,
    required String frontmatter,
    required List<String> tags,
    required String blobSha,
    String? lastCommitSha,
    required DateTime updatedAt,
  }) = _HubDocumentImpl;

  factory HubDocument.fromJson(Map<String, dynamic> jsonSerialization) {
    return HubDocument(
      id: jsonSerialization['id'] as int?,
      hubId: jsonSerialization['hubId'] as int,
      path: jsonSerialization['path'] as String,
      title: jsonSerialization['title'] as String,
      area: jsonSerialization['area'] as String,
      type: jsonSerialization['type'] as String?,
      status: jsonSerialization['status'] as String?,
      frontmatter: jsonSerialization['frontmatter'] as String,
      tags: _iz3sasjg.Protocol().deserialize<List<String>>(
        jsonSerialization['tags'],
      ),
      blobSha: jsonSerialization['blobSha'] as String,
      lastCommitSha: jsonSerialization['lastCommitSha'] as String?,
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int hubId;

  String path;

  String title;

  String area;

  String? type;

  String? status;

  /// Frontmatter sebagai JSON.
  String frontmatter;

  List<String> tags;

  String blobSha;

  String? lastCommitSha;

  DateTime updatedAt;

  /// Returns a shallow copy of this [HubDocument]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  HubDocument copyWith({
    int? id,
    int? hubId,
    String? path,
    String? title,
    String? area,
    String? type,
    String? status,
    String? frontmatter,
    List<String>? tags,
    String? blobSha,
    String? lastCommitSha,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'HubDocument',
      if (id != null) 'id': id,
      'hubId': hubId,
      'path': path,
      'title': title,
      'area': area,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      'frontmatter': frontmatter,
      'tags': tags.toJson(),
      'blobSha': blobSha,
      if (lastCommitSha != null) 'lastCommitSha': lastCommitSha,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'HubDocument',
      if (id != null) 'id': id,
      'hubId': hubId,
      'path': path,
      'title': title,
      'area': area,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      'frontmatter': frontmatter,
      'tags': tags.toJson(),
      'blobSha': blobSha,
      if (lastCommitSha != null) 'lastCommitSha': lastCommitSha,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _HubDocumentImpl extends HubDocument {
  _HubDocumentImpl({
    int? id,
    required int hubId,
    required String path,
    required String title,
    required String area,
    String? type,
    String? status,
    required String frontmatter,
    required List<String> tags,
    required String blobSha,
    String? lastCommitSha,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         hubId: hubId,
         path: path,
         title: title,
         area: area,
         type: type,
         status: status,
         frontmatter: frontmatter,
         tags: tags,
         blobSha: blobSha,
         lastCommitSha: lastCommitSha,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [HubDocument]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  HubDocument copyWith({
    Object? id = _Undefined,
    int? hubId,
    String? path,
    String? title,
    String? area,
    Object? type = _Undefined,
    Object? status = _Undefined,
    String? frontmatter,
    List<String>? tags,
    String? blobSha,
    Object? lastCommitSha = _Undefined,
    DateTime? updatedAt,
  }) {
    return HubDocument(
      id: id is int? ? id : this.id,
      hubId: hubId ?? this.hubId,
      path: path ?? this.path,
      title: title ?? this.title,
      area: area ?? this.area,
      type: type is String? ? type : this.type,
      status: status is String? ? status : this.status,
      frontmatter: frontmatter ?? this.frontmatter,
      tags: tags ?? this.tags.map((e0) => e0).toList(),
      blobSha: blobSha ?? this.blobSha,
      lastCommitSha: lastCommitSha is String?
          ? lastCommitSha
          : this.lastCommitSha,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
