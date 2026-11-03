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

/// Catatan satu backup zip harian.
abstract class BackupRecord
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  BackupRecord._({
    this.id,
    required this.hubId,
    required this.objectKey,
    required this.sizeBytes,
    required this.createdAt,
    required this.status,
    this.error,
  });

  factory BackupRecord({
    int? id,
    required int hubId,
    required String objectKey,
    required int sizeBytes,
    required DateTime createdAt,
    required String status,
    String? error,
  }) = _BackupRecordImpl;

  factory BackupRecord.fromJson(Map<String, dynamic> jsonSerialization) {
    return BackupRecord(
      id: jsonSerialization['id'] as int?,
      hubId: jsonSerialization['hubId'] as int,
      objectKey: jsonSerialization['objectKey'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      status: jsonSerialization['status'] as String,
      error: jsonSerialization['error'] as String?,
    );
  }

  static final t = BackupRecordTable();

  static const db = BackupRecordRepository._();

  @override
  int? id;

  int hubId;

  String objectKey;

  int sizeBytes;

  DateTime createdAt;

  String status;

  String? error;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [BackupRecord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BackupRecord copyWith({
    int? id,
    int? hubId,
    String? objectKey,
    int? sizeBytes,
    DateTime? createdAt,
    String? status,
    String? error,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BackupRecord',
      if (id != null) 'id': id,
      'hubId': hubId,
      'objectKey': objectKey,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toJson(),
      'status': status,
      if (error != null) 'error': error,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BackupRecord',
      if (id != null) 'id': id,
      'hubId': hubId,
      'objectKey': objectKey,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toJson(),
      'status': status,
      if (error != null) 'error': error,
    };
  }

  static BackupRecordInclude include() {
    return BackupRecordInclude._();
  }

  static BackupRecordIncludeList includeList({
    _is.WhereExpressionBuilder<BackupRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BackupRecordTable>? orderBy,
    _is.OrderByListBuilder<BackupRecordTable>? orderByList,
    BackupRecordInclude? include,
  }) {
    return BackupRecordIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BackupRecord.t),
      orderByList: orderByList?.call(BackupRecord.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BackupRecordImpl extends BackupRecord {
  _BackupRecordImpl({
    int? id,
    required int hubId,
    required String objectKey,
    required int sizeBytes,
    required DateTime createdAt,
    required String status,
    String? error,
  }) : super._(
         id: id,
         hubId: hubId,
         objectKey: objectKey,
         sizeBytes: sizeBytes,
         createdAt: createdAt,
         status: status,
         error: error,
       );

  /// Returns a shallow copy of this [BackupRecord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BackupRecord copyWith({
    Object? id = _Undefined,
    int? hubId,
    String? objectKey,
    int? sizeBytes,
    DateTime? createdAt,
    String? status,
    Object? error = _Undefined,
  }) {
    return BackupRecord(
      id: id is int? ? id : this.id,
      hubId: hubId ?? this.hubId,
      objectKey: objectKey ?? this.objectKey,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      error: error is String? ? error : this.error,
    );
  }
}

class BackupRecordUpdateTable extends _is.UpdateTable<BackupRecordTable> {
  BackupRecordUpdateTable(super.table);

  _is.ColumnValue<int, int> hubId(int value) => _is.ColumnValue(
    table.hubId,
    value,
  );

  _is.ColumnValue<String, String> objectKey(String value) => _is.ColumnValue(
    table.objectKey,
    value,
  );

  _is.ColumnValue<int, int> sizeBytes(int value) => _is.ColumnValue(
    table.sizeBytes,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> error(String? value) => _is.ColumnValue(
    table.error,
    value,
  );
}

class BackupRecordTable extends _is.Table<int?> {
  BackupRecordTable({super.tableRelation}) : super(tableName: 'backup') {
    updateTable = BackupRecordUpdateTable(this);
    hubId = _is.ColumnInt(
      'hubId',
      this,
    );
    objectKey = _is.ColumnString(
      'objectKey',
      this,
    );
    sizeBytes = _is.ColumnInt(
      'sizeBytes',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    error = _is.ColumnString(
      'error',
      this,
    );
  }

  late final BackupRecordUpdateTable updateTable;

  late final _is.ColumnInt hubId;

  late final _is.ColumnString objectKey;

  late final _is.ColumnInt sizeBytes;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnString status;

  late final _is.ColumnString error;

  @override
  List<_is.Column> get columns => [
    id,
    hubId,
    objectKey,
    sizeBytes,
    createdAt,
    status,
    error,
  ];
}

class BackupRecordInclude extends _is.IncludeObject {
  BackupRecordInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => BackupRecord.t;
}

class BackupRecordIncludeList extends _is.IncludeList {
  BackupRecordIncludeList._({
    _is.WhereExpressionBuilder<BackupRecordTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BackupRecord.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => BackupRecord.t;
}

class BackupRecordRepository {
  const BackupRecordRepository._();

  /// Returns a list of [BackupRecord]s matching the given query parameters.
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
  Future<List<BackupRecord>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BackupRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BackupRecordTable>? orderBy,
    _is.OrderByListBuilder<BackupRecordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<BackupRecord>(
      where: where?.call(BackupRecord.t),
      orderBy: orderBy?.call(BackupRecord.t),
      orderByList: orderByList?.call(BackupRecord.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [BackupRecord]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `BackupRecord.t`.
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
  _ida.Stream<List<BackupRecord>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BackupRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BackupRecordTable>? orderBy,
    _is.OrderByListBuilder<BackupRecordTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<BackupRecord>(
      where: where?.call(BackupRecord.t),
      orderBy: orderBy?.call(BackupRecord.t),
      orderByList: orderByList?.call(BackupRecord.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [BackupRecord] matching the given query parameters.
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
  Future<BackupRecord?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BackupRecordTable>? where,
    int? offset,
    _is.OrderByBuilder<BackupRecordTable>? orderBy,
    _is.OrderByListBuilder<BackupRecordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<BackupRecord>(
      where: where?.call(BackupRecord.t),
      orderBy: orderBy?.call(BackupRecord.t),
      orderByList: orderByList?.call(BackupRecord.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [BackupRecord] by its [id] or null if no such row exists.
  Future<BackupRecord?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<BackupRecord>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [BackupRecord]s in the list and returns the inserted rows.
  ///
  /// The returned [BackupRecord]s will have their `id` fields set.
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
  Future<List<BackupRecord>> insert(
    _is.DatabaseSession session,
    List<BackupRecord> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<BackupRecord>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [BackupRecord] and returns the inserted row.
  ///
  /// The returned [BackupRecord] will have its `id` field set.
  Future<BackupRecord> insertRow(
    _is.DatabaseSession session,
    BackupRecord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<BackupRecord>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [BackupRecord]s in the list and returns the resulting rows.
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
  /// The returned [BackupRecord]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BackupRecord>> upsert(
    _is.DatabaseSession session,
    List<BackupRecord> rows, {
    required _is.ColumnSelections<BackupRecordTable> conflictColumns,
    _is.ColumnSelections<BackupRecordTable>? updateColumns,
    _is.WhereExpressionBuilder<BackupRecordTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<BackupRecord>(
      rows,
      conflictColumns: conflictColumns(BackupRecord.t),
      updateColumns: updateColumns?.call(BackupRecord.t),
      updateWhere: updateWhere?.call(BackupRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [BackupRecord] and returns the resulting row.
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
  /// The returned [BackupRecord] will have its `id` field set.
  Future<BackupRecord?> upsertRow(
    _is.DatabaseSession session,
    BackupRecord row, {
    required _is.ColumnSelections<BackupRecordTable> conflictColumns,
    _is.ColumnSelections<BackupRecordTable>? updateColumns,
    _is.WhereExpressionBuilder<BackupRecordTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<BackupRecord>(
      row,
      conflictColumns: conflictColumns(BackupRecord.t),
      updateColumns: updateColumns?.call(BackupRecord.t),
      updateWhere: updateWhere?.call(BackupRecord.t),
      transaction: transaction,
    );
  }

  /// Updates all [BackupRecord]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BackupRecord>> update(
    _is.DatabaseSession session,
    List<BackupRecord> rows, {
    _is.ColumnSelections<BackupRecordTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<BackupRecord>(
      rows,
      columns: columns?.call(BackupRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [BackupRecord]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BackupRecord> updateRow(
    _is.DatabaseSession session,
    BackupRecord row, {
    _is.ColumnSelections<BackupRecordTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<BackupRecord>(
      row,
      columns: columns?.call(BackupRecord.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BackupRecord] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<BackupRecord?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<BackupRecordUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<BackupRecord>(
      id,
      columnValues: columnValues(BackupRecord.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [BackupRecord]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BackupRecord>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<BackupRecordUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<BackupRecordTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BackupRecordTable>? orderBy,
    _is.OrderByListBuilder<BackupRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<BackupRecord>(
      columnValues: columnValues(BackupRecord.t.updateTable),
      where: where(BackupRecord.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BackupRecord.t),
      orderByList: orderByList?.call(BackupRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [BackupRecord]s in the list and returns the deleted rows.
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
  Future<List<BackupRecord>> delete(
    _is.DatabaseSession session,
    List<BackupRecord> rows, {
    _is.OrderByBuilder<BackupRecordTable>? orderBy,
    _is.OrderByListBuilder<BackupRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<BackupRecord>(
      rows,
      orderBy: orderBy?.call(BackupRecord.t),
      orderByList: orderByList?.call(BackupRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [BackupRecord].
  Future<BackupRecord> deleteRow(
    _is.DatabaseSession session,
    BackupRecord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BackupRecord>(
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
  Future<List<BackupRecord>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BackupRecordTable> where,
    _is.OrderByBuilder<BackupRecordTable>? orderBy,
    _is.OrderByListBuilder<BackupRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<BackupRecord>(
      where: where(BackupRecord.t),
      orderBy: orderBy?.call(BackupRecord.t),
      orderByList: orderByList?.call(BackupRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BackupRecordTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<BackupRecord>(
      where: where?.call(BackupRecord.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [BackupRecord] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BackupRecordTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<BackupRecord>(
      where: where(BackupRecord.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
