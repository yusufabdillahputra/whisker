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

/// Wikilink dari satu dokumen ke target (path/nama), resolusi opsional.
abstract class DocumentLink
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DocumentLink._({
    this.id,
    required this.fromDocId,
    required this.hubId,
    required this.toPath,
    this.toDocId,
  });

  factory DocumentLink({
    int? id,
    required int fromDocId,
    required int hubId,
    required String toPath,
    int? toDocId,
  }) = _DocumentLinkImpl;

  factory DocumentLink.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocumentLink(
      id: jsonSerialization['id'] as int?,
      fromDocId: jsonSerialization['fromDocId'] as int,
      hubId: jsonSerialization['hubId'] as int,
      toPath: jsonSerialization['toPath'] as String,
      toDocId: jsonSerialization['toDocId'] as int?,
    );
  }

  static final t = DocumentLinkTable();

  static const db = DocumentLinkRepository._();

  @override
  int? id;

  int fromDocId;

  int hubId;

  String toPath;

  int? toDocId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DocumentLink]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DocumentLink copyWith({
    int? id,
    int? fromDocId,
    int? hubId,
    String? toPath,
    int? toDocId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocumentLink',
      if (id != null) 'id': id,
      'fromDocId': fromDocId,
      'hubId': hubId,
      'toPath': toPath,
      if (toDocId != null) 'toDocId': toDocId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocumentLink',
      if (id != null) 'id': id,
      'fromDocId': fromDocId,
      'hubId': hubId,
      'toPath': toPath,
      if (toDocId != null) 'toDocId': toDocId,
    };
  }

  static DocumentLinkInclude include() {
    return DocumentLinkInclude._();
  }

  static DocumentLinkIncludeList includeList({
    _is.WhereExpressionBuilder<DocumentLinkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentLinkTable>? orderBy,
    _is.OrderByListBuilder<DocumentLinkTable>? orderByList,
    DocumentLinkInclude? include,
  }) {
    return DocumentLinkIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DocumentLink.t),
      orderByList: orderByList?.call(DocumentLink.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentLinkImpl extends DocumentLink {
  _DocumentLinkImpl({
    int? id,
    required int fromDocId,
    required int hubId,
    required String toPath,
    int? toDocId,
  }) : super._(
         id: id,
         fromDocId: fromDocId,
         hubId: hubId,
         toPath: toPath,
         toDocId: toDocId,
       );

  /// Returns a shallow copy of this [DocumentLink]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DocumentLink copyWith({
    Object? id = _Undefined,
    int? fromDocId,
    int? hubId,
    String? toPath,
    Object? toDocId = _Undefined,
  }) {
    return DocumentLink(
      id: id is int? ? id : this.id,
      fromDocId: fromDocId ?? this.fromDocId,
      hubId: hubId ?? this.hubId,
      toPath: toPath ?? this.toPath,
      toDocId: toDocId is int? ? toDocId : this.toDocId,
    );
  }
}

class DocumentLinkUpdateTable extends _is.UpdateTable<DocumentLinkTable> {
  DocumentLinkUpdateTable(super.table);

  _is.ColumnValue<int, int> fromDocId(int value) => _is.ColumnValue(
    table.fromDocId,
    value,
  );

  _is.ColumnValue<int, int> hubId(int value) => _is.ColumnValue(
    table.hubId,
    value,
  );

  _is.ColumnValue<String, String> toPath(String value) => _is.ColumnValue(
    table.toPath,
    value,
  );

  _is.ColumnValue<int, int> toDocId(int? value) => _is.ColumnValue(
    table.toDocId,
    value,
  );
}

class DocumentLinkTable extends _is.Table<int?> {
  DocumentLinkTable({super.tableRelation}) : super(tableName: 'document_link') {
    updateTable = DocumentLinkUpdateTable(this);
    fromDocId = _is.ColumnInt(
      'fromDocId',
      this,
    );
    hubId = _is.ColumnInt(
      'hubId',
      this,
    );
    toPath = _is.ColumnString(
      'toPath',
      this,
    );
    toDocId = _is.ColumnInt(
      'toDocId',
      this,
    );
  }

  late final DocumentLinkUpdateTable updateTable;

  late final _is.ColumnInt fromDocId;

  late final _is.ColumnInt hubId;

  late final _is.ColumnString toPath;

  late final _is.ColumnInt toDocId;

  @override
  List<_is.Column> get columns => [
    id,
    fromDocId,
    hubId,
    toPath,
    toDocId,
  ];
}

class DocumentLinkInclude extends _is.IncludeObject {
  DocumentLinkInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DocumentLink.t;
}

class DocumentLinkIncludeList extends _is.IncludeList {
  DocumentLinkIncludeList._({
    _is.WhereExpressionBuilder<DocumentLinkTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DocumentLink.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DocumentLink.t;
}

class DocumentLinkRepository {
  const DocumentLinkRepository._();

  /// Returns a list of [DocumentLink]s matching the given query parameters.
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
  Future<List<DocumentLink>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentLinkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentLinkTable>? orderBy,
    _is.OrderByListBuilder<DocumentLinkTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DocumentLink>(
      where: where?.call(DocumentLink.t),
      orderBy: orderBy?.call(DocumentLink.t),
      orderByList: orderByList?.call(DocumentLink.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [DocumentLink]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `DocumentLink.t`.
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
  _ida.Stream<List<DocumentLink>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentLinkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentLinkTable>? orderBy,
    _is.OrderByListBuilder<DocumentLinkTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<DocumentLink>(
      where: where?.call(DocumentLink.t),
      orderBy: orderBy?.call(DocumentLink.t),
      orderByList: orderByList?.call(DocumentLink.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [DocumentLink] matching the given query parameters.
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
  Future<DocumentLink?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentLinkTable>? where,
    int? offset,
    _is.OrderByBuilder<DocumentLinkTable>? orderBy,
    _is.OrderByListBuilder<DocumentLinkTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DocumentLink>(
      where: where?.call(DocumentLink.t),
      orderBy: orderBy?.call(DocumentLink.t),
      orderByList: orderByList?.call(DocumentLink.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DocumentLink] by its [id] or null if no such row exists.
  Future<DocumentLink?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DocumentLink>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DocumentLink]s in the list and returns the inserted rows.
  ///
  /// The returned [DocumentLink]s will have their `id` fields set.
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
  Future<List<DocumentLink>> insert(
    _is.DatabaseSession session,
    List<DocumentLink> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DocumentLink>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DocumentLink] and returns the inserted row.
  ///
  /// The returned [DocumentLink] will have its `id` field set.
  Future<DocumentLink> insertRow(
    _is.DatabaseSession session,
    DocumentLink row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DocumentLink>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DocumentLink]s in the list and returns the resulting rows.
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
  /// The returned [DocumentLink]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentLink>> upsert(
    _is.DatabaseSession session,
    List<DocumentLink> rows, {
    required _is.ColumnSelections<DocumentLinkTable> conflictColumns,
    _is.ColumnSelections<DocumentLinkTable>? updateColumns,
    _is.WhereExpressionBuilder<DocumentLinkTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DocumentLink>(
      rows,
      conflictColumns: conflictColumns(DocumentLink.t),
      updateColumns: updateColumns?.call(DocumentLink.t),
      updateWhere: updateWhere?.call(DocumentLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DocumentLink] and returns the resulting row.
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
  /// The returned [DocumentLink] will have its `id` field set.
  Future<DocumentLink?> upsertRow(
    _is.DatabaseSession session,
    DocumentLink row, {
    required _is.ColumnSelections<DocumentLinkTable> conflictColumns,
    _is.ColumnSelections<DocumentLinkTable>? updateColumns,
    _is.WhereExpressionBuilder<DocumentLinkTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DocumentLink>(
      row,
      conflictColumns: conflictColumns(DocumentLink.t),
      updateColumns: updateColumns?.call(DocumentLink.t),
      updateWhere: updateWhere?.call(DocumentLink.t),
      transaction: transaction,
    );
  }

  /// Updates all [DocumentLink]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentLink>> update(
    _is.DatabaseSession session,
    List<DocumentLink> rows, {
    _is.ColumnSelections<DocumentLinkTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DocumentLink>(
      rows,
      columns: columns?.call(DocumentLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DocumentLink]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DocumentLink> updateRow(
    _is.DatabaseSession session,
    DocumentLink row, {
    _is.ColumnSelections<DocumentLinkTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DocumentLink>(
      row,
      columns: columns?.call(DocumentLink.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DocumentLink] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DocumentLink?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DocumentLinkUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DocumentLink>(
      id,
      columnValues: columnValues(DocumentLink.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DocumentLink]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentLink>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DocumentLinkUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DocumentLinkTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentLinkTable>? orderBy,
    _is.OrderByListBuilder<DocumentLinkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DocumentLink>(
      columnValues: columnValues(DocumentLink.t.updateTable),
      where: where(DocumentLink.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DocumentLink.t),
      orderByList: orderByList?.call(DocumentLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DocumentLink]s in the list and returns the deleted rows.
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
  Future<List<DocumentLink>> delete(
    _is.DatabaseSession session,
    List<DocumentLink> rows, {
    _is.OrderByBuilder<DocumentLinkTable>? orderBy,
    _is.OrderByListBuilder<DocumentLinkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DocumentLink>(
      rows,
      orderBy: orderBy?.call(DocumentLink.t),
      orderByList: orderByList?.call(DocumentLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DocumentLink].
  Future<DocumentLink> deleteRow(
    _is.DatabaseSession session,
    DocumentLink row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DocumentLink>(
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
  Future<List<DocumentLink>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DocumentLinkTable> where,
    _is.OrderByBuilder<DocumentLinkTable>? orderBy,
    _is.OrderByListBuilder<DocumentLinkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DocumentLink>(
      where: where(DocumentLink.t),
      orderBy: orderBy?.call(DocumentLink.t),
      orderByList: orderByList?.call(DocumentLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentLinkTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DocumentLink>(
      where: where?.call(DocumentLink.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DocumentLink] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DocumentLinkTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DocumentLink>(
      where: where(DocumentLink.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
