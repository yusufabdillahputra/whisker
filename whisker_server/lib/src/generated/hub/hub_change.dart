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
import 'package:whisker_server/src/generated/protocol.dart' as _if8lny2t;

/// Siaran "Hub berubah" ke aplikasi.
abstract class HubChange
    implements _is.SerializableModel, _is.ProtocolSerialization {
  HubChange._({
    required this.hubId,
    required this.headSha,
    required this.paths,
  });

  factory HubChange({
    required int hubId,
    required String headSha,
    required List<String> paths,
  }) = _HubChangeImpl;

  factory HubChange.fromJson(Map<String, dynamic> jsonSerialization) {
    return HubChange(
      hubId: jsonSerialization['hubId'] as int,
      headSha: jsonSerialization['headSha'] as String,
      paths: _if8lny2t.Protocol().deserialize<List<String>>(
        jsonSerialization['paths'],
      ),
    );
  }

  int hubId;

  String headSha;

  List<String> paths;

  /// Returns a shallow copy of this [HubChange]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  HubChange copyWith({
    int? hubId,
    String? headSha,
    List<String>? paths,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'HubChange',
      'hubId': hubId,
      'headSha': headSha,
      'paths': paths.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'HubChange',
      'hubId': hubId,
      'headSha': headSha,
      'paths': paths.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _HubChangeImpl extends HubChange {
  _HubChangeImpl({
    required int hubId,
    required String headSha,
    required List<String> paths,
  }) : super._(
         hubId: hubId,
         headSha: headSha,
         paths: paths,
       );

  /// Returns a shallow copy of this [HubChange]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  HubChange copyWith({
    int? hubId,
    String? headSha,
    List<String>? paths,
  }) {
    return HubChange(
      hubId: hubId ?? this.hubId,
      headSha: headSha ?? this.headSha,
      paths: paths ?? this.paths.map((e0) => e0).toList(),
    );
  }
}
