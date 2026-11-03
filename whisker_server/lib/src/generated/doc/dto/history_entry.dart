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

abstract class HistoryEntry
    implements _is.SerializableModel, _is.ProtocolSerialization {
  HistoryEntry._({
    required this.sha,
    required this.message,
    required this.authorName,
    required this.date,
  });

  factory HistoryEntry({
    required String sha,
    required String message,
    required String authorName,
    required DateTime date,
  }) = _HistoryEntryImpl;

  factory HistoryEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return HistoryEntry(
      sha: jsonSerialization['sha'] as String,
      message: jsonSerialization['message'] as String,
      authorName: jsonSerialization['authorName'] as String,
      date: _is.DateTimeJsonExtension.fromJson(jsonSerialization['date']),
    );
  }

  String sha;

  String message;

  String authorName;

  DateTime date;

  /// Returns a shallow copy of this [HistoryEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  HistoryEntry copyWith({
    String? sha,
    String? message,
    String? authorName,
    DateTime? date,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'HistoryEntry',
      'sha': sha,
      'message': message,
      'authorName': authorName,
      'date': date.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'HistoryEntry',
      'sha': sha,
      'message': message,
      'authorName': authorName,
      'date': date.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _HistoryEntryImpl extends HistoryEntry {
  _HistoryEntryImpl({
    required String sha,
    required String message,
    required String authorName,
    required DateTime date,
  }) : super._(
         sha: sha,
         message: message,
         authorName: authorName,
         date: date,
       );

  /// Returns a shallow copy of this [HistoryEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  HistoryEntry copyWith({
    String? sha,
    String? message,
    String? authorName,
    DateTime? date,
  }) {
    return HistoryEntry(
      sha: sha ?? this.sha,
      message: message ?? this.message,
      authorName: authorName ?? this.authorName,
      date: date ?? this.date,
    );
  }
}
