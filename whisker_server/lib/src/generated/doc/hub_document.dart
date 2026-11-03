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
import 'dart:async' as _ida;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:whisker_server/src/generated/protocol.dart' as _if8lny2t;

/// Indeks satu file markdown di Hub (turunan repo; isi tidak disimpan).
abstract class HubDocument
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
      tags: _if8lny2t.Protocol().deserialize<List<String>>(
        jsonSerialization['tags'],
      ),
      blobSha: jsonSerialization['blobSha'] as String,
      lastCommitSha: jsonSerialization['lastCommitSha'] as String?,
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = HubDocumentTable();

  static const db = HubDocumentRepository._();

  @override
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

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [HubDocument]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static HubDocumentInclude include() {
    return HubDocumentInclude._();
  }

  static HubDocumentIncludeList includeList({
    _is.WhereExpressionBuilder<HubDocumentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<HubDocumentTable>? orderBy,
    _is.OrderByListBuilder<HubDocumentTable>? orderByList,
    HubDocumentInclude? include,
  }) {
    return HubDocumentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(HubDocument.t),
      orderByList: orderByList?.call(HubDocument.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class HubDocumentUpdateTable extends _is.UpdateTable<HubDocumentTable> {
  HubDocumentUpdateTable(super.table);

  _is.ColumnValue<int, int> hubId(int value) => _is.ColumnValue(
    table.hubId,
    value,
  );

  _is.ColumnValue<String, String> path(String value) => _is.ColumnValue(
    table.path,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> area(String value) => _is.ColumnValue(
    table.area,
    value,
  );

  _is.ColumnValue<String, String> type(String? value) => _is.ColumnValue(
    table.type,
    value,
  );

  _is.ColumnValue<String, String> status(String? value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> frontmatter(String value) => _is.ColumnValue(
    table.frontmatter,
    value,
  );

  _is.ColumnValue<List<String>, List<String>> tags(List<String> value) =>
      _is.ColumnValue(
        table.tags,
        value,
      );

  _is.ColumnValue<String, String> blobSha(String value) => _is.ColumnValue(
    table.blobSha,
    value,
  );

  _is.ColumnValue<String, String> lastCommitSha(String? value) =>
      _is.ColumnValue(
        table.lastCommitSha,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class HubDocumentTable extends _is.Table<int?> {
  HubDocumentTable({super.tableRelation}) : super(tableName: 'document') {
    updateTable = HubDocumentUpdateTable(this);
    hubId = _is.ColumnInt(
      'hubId',
      this,
    );
    path = _is.ColumnString(
      'path',
      this,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    area = _is.ColumnString(
      'area',
      this,
    );
    type = _is.ColumnString(
      'type',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    frontmatter = _is.ColumnString(
      'frontmatter',
      this,
    );
    tags = _is.ColumnSerializable<List<String>>(
      'tags',
      this,
    );
    blobSha = _is.ColumnString(
      'blobSha',
      this,
    );
    lastCommitSha = _is.ColumnString(
      'lastCommitSha',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final HubDocumentUpdateTable updateTable;

  late final _is.ColumnInt hubId;

  late final _is.ColumnString path;

  late final _is.ColumnString title;

  late final _is.ColumnString area;

  late final _is.ColumnString type;

  late final _is.ColumnString status;

  /// Frontmatter sebagai JSON.
  late final _is.ColumnString frontmatter;

  late final _is.ColumnSerializable<List<String>> tags;

  late final _is.ColumnString blobSha;

  late final _is.ColumnString lastCommitSha;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    hubId,
    path,
    title,
    area,
    type,
    status,
    frontmatter,
    tags,
    blobSha,
    lastCommitSha,
    updatedAt,
  ];
}

class HubDocumentInclude extends _is.IncludeObject {
  HubDocumentInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => HubDocument.t;
}

class HubDocumentIncludeList extends _is.IncludeList {
  HubDocumentIncludeList._({
    _is.WhereExpressionBuilder<HubDocumentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(HubDocument.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => HubDocument.t;
}

class HubDocumentRepository {
  const HubDocumentRepository._();

  /// Returns a list of [HubDocument]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<HubDocument>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<HubDocumentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<HubDocumentTable>? orderBy,
    _is.OrderByListBuilder<HubDocumentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<HubDocument>(
      where: where?.call(HubDocument.t),
      orderBy: orderBy?.call(HubDocument.t),
      orderByList: orderByList?.call(HubDocument.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [HubDocument]s matching the given query parameters every time the
  /// source tables are modified.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// Use [throttle] to specify the minimum interval between queries. It can
  /// also be set to `null`, in which case the stream will only be throttled
  /// when its subscription is paused.
  ///
  /// Source tables are collected from the queried table, [where], [orderBy],
  /// [orderByList], and the [include] graph. [alsoTriggerOnTables] is added
  /// to that set. Pass [Table] instances such as `HubDocument.t`.
  ///
  /// Raw [Expression] SQL is not inspected. Tables referenced only in raw
  /// SQL must be passed via [alsoTriggerOnTables].
  ///
  /// The stream always reads committed state and never joins an ambient
  /// [Transaction]. Emissions for a write fire after that write commits.
  ///
  /// Currently only supported on SQLite. Calling this method on PostgreSQL
  /// throws an [UnsupportedError].
  ///
  /// ```dart
  /// var subscription = Persons.db.watch(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// ).listen((persons) {
  ///   // Handle the latest matching rows.
  /// });
  /// ```
  _ida.Stream<List<HubDocument>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<HubDocumentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<HubDocumentTable>? orderBy,
    _is.OrderByListBuilder<HubDocumentTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<HubDocument>(
      where: where?.call(HubDocument.t),
      orderBy: orderBy?.call(HubDocument.t),
      orderByList: orderByList?.call(HubDocument.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [HubDocument] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<HubDocument?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<HubDocumentTable>? where,
    int? offset,
    _is.OrderByBuilder<HubDocumentTable>? orderBy,
    _is.OrderByListBuilder<HubDocumentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<HubDocument>(
      where: where?.call(HubDocument.t),
      orderBy: orderBy?.call(HubDocument.t),
      orderByList: orderByList?.call(HubDocument.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [HubDocument] by its [id] or null if no such row exists.
  Future<HubDocument?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<HubDocument>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [HubDocument]s in the list and returns the inserted rows.
  ///
  /// The returned [HubDocument]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<HubDocument>> insert(
    _is.DatabaseSession session,
    List<HubDocument> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<HubDocument>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [HubDocument] and returns the inserted row.
  ///
  /// The returned [HubDocument] will have its `id` field set.
  Future<HubDocument> insertRow(
    _is.DatabaseSession session,
    HubDocument row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<HubDocument>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [HubDocument]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [HubDocument]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<HubDocument>> upsert(
    _is.DatabaseSession session,
    List<HubDocument> rows, {
    required _is.ColumnSelections<HubDocumentTable> conflictColumns,
    _is.ColumnSelections<HubDocumentTable>? updateColumns,
    _is.WhereExpressionBuilder<HubDocumentTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<HubDocument>(
      rows,
      conflictColumns: conflictColumns(HubDocument.t),
      updateColumns: updateColumns?.call(HubDocument.t),
      updateWhere: updateWhere?.call(HubDocument.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [HubDocument] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [HubDocument] will have its `id` field set.
  Future<HubDocument?> upsertRow(
    _is.DatabaseSession session,
    HubDocument row, {
    required _is.ColumnSelections<HubDocumentTable> conflictColumns,
    _is.ColumnSelections<HubDocumentTable>? updateColumns,
    _is.WhereExpressionBuilder<HubDocumentTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<HubDocument>(
      row,
      conflictColumns: conflictColumns(HubDocument.t),
      updateColumns: updateColumns?.call(HubDocument.t),
      updateWhere: updateWhere?.call(HubDocument.t),
      transaction: transaction,
    );
  }

  /// Updates all [HubDocument]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<HubDocument>> update(
    _is.DatabaseSession session,
    List<HubDocument> rows, {
    _is.ColumnSelections<HubDocumentTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<HubDocument>(
      rows,
      columns: columns?.call(HubDocument.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [HubDocument]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<HubDocument> updateRow(
    _is.DatabaseSession session,
    HubDocument row, {
    _is.ColumnSelections<HubDocumentTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<HubDocument>(
      row,
      columns: columns?.call(HubDocument.t),
      transaction: transaction,
    );
  }

  /// Updates a single [HubDocument] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<HubDocument?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<HubDocumentUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<HubDocument>(
      id,
      columnValues: columnValues(HubDocument.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [HubDocument]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<HubDocument>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<HubDocumentUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<HubDocumentTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<HubDocumentTable>? orderBy,
    _is.OrderByListBuilder<HubDocumentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<HubDocument>(
      columnValues: columnValues(HubDocument.t.updateTable),
      where: where(HubDocument.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(HubDocument.t),
      orderByList: orderByList?.call(HubDocument.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [HubDocument]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<HubDocument>> delete(
    _is.DatabaseSession session,
    List<HubDocument> rows, {
    _is.OrderByBuilder<HubDocumentTable>? orderBy,
    _is.OrderByListBuilder<HubDocumentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<HubDocument>(
      rows,
      orderBy: orderBy?.call(HubDocument.t),
      orderByList: orderByList?.call(HubDocument.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [HubDocument].
  Future<HubDocument> deleteRow(
    _is.DatabaseSession session,
    HubDocument row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<HubDocument>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<HubDocument>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<HubDocumentTable> where,
    _is.OrderByBuilder<HubDocumentTable>? orderBy,
    _is.OrderByListBuilder<HubDocumentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<HubDocument>(
      where: where(HubDocument.t),
      orderBy: orderBy?.call(HubDocument.t),
      orderByList: orderByList?.call(HubDocument.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<HubDocumentTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<HubDocument>(
      where: where?.call(HubDocument.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [HubDocument] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<HubDocumentTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<HubDocument>(
      where: where(HubDocument.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
