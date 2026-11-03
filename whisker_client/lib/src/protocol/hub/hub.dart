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

/// Satu Hub = satu repo git berisi vault markdown.
abstract class Hub
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Hub._({
    this.id,
    required this.name,
    required this.slug,
    this.githubRepo,
    required this.remoteUrl,
    this.installationId,
    String? defaultBranch,
    this.headSha,
    this.lastIndexedAt,
    required this.ownerId,
  }) : defaultBranch = defaultBranch ?? 'main';

  factory Hub({
    int? id,
    required String name,
    required String slug,
    String? githubRepo,
    required String remoteUrl,
    int? installationId,
    String? defaultBranch,
    String? headSha,
    DateTime? lastIndexedAt,
    required _isc.UuidValue ownerId,
  }) = _HubImpl;

  factory Hub.fromJson(Map<String, dynamic> jsonSerialization) {
    return Hub(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      slug: jsonSerialization['slug'] as String,
      githubRepo: jsonSerialization['githubRepo'] as String?,
      remoteUrl: jsonSerialization['remoteUrl'] as String,
      installationId: jsonSerialization['installationId'] as int?,
      defaultBranch: jsonSerialization['defaultBranch'] as String?,
      headSha: jsonSerialization['headSha'] as String?,
      lastIndexedAt: jsonSerialization['lastIndexedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastIndexedAt'],
            ),
      ownerId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['ownerId'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String name;

  String slug;

  /// `owner/name` di GitHub, bila repo ada di GitHub.
  String? githubRepo;

  /// URL clone tanpa kredensial (https GitHub atau path lokal untuk dev/test).
  String remoteUrl;

  int? installationId;

  String defaultBranch;

  String? headSha;

  DateTime? lastIndexedAt;

  _isc.UuidValue ownerId;

  /// Returns a shallow copy of this [Hub]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Hub copyWith({
    int? id,
    String? name,
    String? slug,
    String? githubRepo,
    String? remoteUrl,
    int? installationId,
    String? defaultBranch,
    String? headSha,
    DateTime? lastIndexedAt = const _isc.$UndefinedDateTime(),
    _isc.UuidValue? ownerId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Hub',
      if (id != null) 'id': id,
      'name': name,
      'slug': slug,
      if (githubRepo != null) 'githubRepo': githubRepo,
      'remoteUrl': remoteUrl,
      if (installationId != null) 'installationId': installationId,
      'defaultBranch': defaultBranch,
      if (headSha != null) 'headSha': headSha,
      if (lastIndexedAt != null) 'lastIndexedAt': lastIndexedAt?.toJson(),
      'ownerId': ownerId.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Hub',
      if (id != null) 'id': id,
      'name': name,
      'slug': slug,
      if (githubRepo != null) 'githubRepo': githubRepo,
      'remoteUrl': remoteUrl,
      if (installationId != null) 'installationId': installationId,
      'defaultBranch': defaultBranch,
      if (headSha != null) 'headSha': headSha,
      if (lastIndexedAt != null) 'lastIndexedAt': lastIndexedAt?.toJson(),
      'ownerId': ownerId.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _HubImpl extends Hub {
  _HubImpl({
    int? id,
    required String name,
    required String slug,
    String? githubRepo,
    required String remoteUrl,
    int? installationId,
    String? defaultBranch,
    String? headSha,
    DateTime? lastIndexedAt,
    required _isc.UuidValue ownerId,
  }) : super._(
         id: id,
         name: name,
         slug: slug,
         githubRepo: githubRepo,
         remoteUrl: remoteUrl,
         installationId: installationId,
         defaultBranch: defaultBranch,
         headSha: headSha,
         lastIndexedAt: lastIndexedAt,
         ownerId: ownerId,
       );

  /// Returns a shallow copy of this [Hub]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Hub copyWith({
    Object? id = _Undefined,
    String? name,
    String? slug,
    Object? githubRepo = _Undefined,
    String? remoteUrl,
    Object? installationId = _Undefined,
    String? defaultBranch,
    Object? headSha = _Undefined,
    DateTime? lastIndexedAt = const _isc.$UndefinedDateTime(),
    _isc.UuidValue? ownerId,
  }) {
    return Hub(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      githubRepo: githubRepo is String? ? githubRepo : this.githubRepo,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      installationId: installationId is int?
          ? installationId
          : this.installationId,
      defaultBranch: defaultBranch ?? this.defaultBranch,
      headSha: headSha is String? ? headSha : this.headSha,
      lastIndexedAt: lastIndexedAt is _isc.UndefinedSentinel
          ? this.lastIndexedAt
          : lastIndexedAt,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
