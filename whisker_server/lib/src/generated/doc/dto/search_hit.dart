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

abstract class SearchHit
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SearchHit._({
    required this.path,
    required this.title,
    required this.snippet,
    required this.rank,
  });

  factory SearchHit({
    required String path,
    required String title,
    required String snippet,
    required double rank,
  }) = _SearchHitImpl;

  factory SearchHit.fromJson(Map<String, dynamic> jsonSerialization) {
    return SearchHit(
      path: jsonSerialization['path'] as String,
      title: jsonSerialization['title'] as String,
      snippet: jsonSerialization['snippet'] as String,
      rank: (jsonSerialization['rank'] as num).toDouble(),
    );
  }

  String path;

  String title;

  String snippet;

  double rank;

  /// Returns a shallow copy of this [SearchHit]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SearchHit copyWith({
    String? path,
    String? title,
    String? snippet,
    double? rank,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchHit',
      'path': path,
      'title': title,
      'snippet': snippet,
      'rank': rank,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SearchHit',
      'path': path,
      'title': title,
      'snippet': snippet,
      'rank': rank,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _SearchHitImpl extends SearchHit {
  _SearchHitImpl({
    required String path,
    required String title,
    required String snippet,
    required double rank,
  }) : super._(
         path: path,
         title: title,
         snippet: snippet,
         rank: rank,
       );

  /// Returns a shallow copy of this [SearchHit]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SearchHit copyWith({
    String? path,
    String? title,
    String? snippet,
    double? rank,
  }) {
    return SearchHit(
      path: path ?? this.path,
      title: title ?? this.title,
      snippet: snippet ?? this.snippet,
      rank: rank ?? this.rank,
    );
  }
}
