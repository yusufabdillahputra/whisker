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

/// Satu Hub = satu repo git berisi vault markdown.
abstract class Hub implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
    required _is.UuidValue ownerId,
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
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastIndexedAt'],
            ),
      ownerId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['ownerId'],
      ),
    );
  }

  static final t = HubTable();

  static const db = HubRepository._();

  @override
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

  _is.UuidValue ownerId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Hub]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Hub copyWith({
    int? id,
    String? name,
    String? slug,
    String? githubRepo,
    String? remoteUrl,
    int? installationId,
    String? defaultBranch,
    String? headSha,
    DateTime? lastIndexedAt = const _is.$UndefinedDateTime(),
    _is.UuidValue? ownerId,
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

  static HubInclude include() {
    return HubInclude._();
  }

  static HubIncludeList includeList({
    _is.WhereExpressionBuilder<HubTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<HubTable>? orderBy,
    _is.OrderByListBuilder<HubTable>? orderByList,
    HubInclude? include,
  }) {
    return HubIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Hub.t),
      orderByList: orderByList?.call(Hub.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
    required _is.UuidValue ownerId,
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
  @_is.useResult
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
    DateTime? lastIndexedAt = const _is.$UndefinedDateTime(),
    _is.UuidValue? ownerId,
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
      lastIndexedAt: lastIndexedAt is _is.UndefinedSentinel
          ? this.lastIndexedAt
          : lastIndexedAt,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}

class HubUpdateTable extends _is.UpdateTable<HubTable> {
  HubUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> slug(String value) => _is.ColumnValue(
    table.slug,
    value,
  );

  _is.ColumnValue<String, String> githubRepo(String? value) => _is.ColumnValue(
    table.githubRepo,
    value,
  );

  _is.ColumnValue<String, String> remoteUrl(String value) => _is.ColumnValue(
    table.remoteUrl,
    value,
  );

  _is.ColumnValue<int, int> installationId(int? value) => _is.ColumnValue(
    table.installationId,
    value,
  );

  _is.ColumnValue<String, String> defaultBranch(String value) =>
      _is.ColumnValue(
        table.defaultBranch,
        value,
      );

  _is.ColumnValue<String, String> headSha(String? value) => _is.ColumnValue(
    table.headSha,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> lastIndexedAt(DateTime? value) =>
      _is.ColumnValue(
        table.lastIndexedAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> ownerId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.ownerId,
        value,
      );
}

class HubTable extends _is.Table<int?> {
  HubTable({super.tableRelation}) : super(tableName: 'hub') {
    updateTable = HubUpdateTable(this);
    name = _is.ColumnString(
      'name',
      this,
    );
    slug = _is.ColumnString(
      'slug',
      this,
    );
    githubRepo = _is.ColumnString(
      'githubRepo',
      this,
    );
    remoteUrl = _is.ColumnString(
      'remoteUrl',
      this,
    );
    installationId = _is.ColumnInt(
      'installationId',
      this,
    );
    defaultBranch = _is.ColumnString(
      'defaultBranch',
      this,
      hasDefault: true,
    );
    headSha = _is.ColumnString(
      'headSha',
      this,
    );
    lastIndexedAt = _is.ColumnDateTime(
      'lastIndexedAt',
      this,
    );
    ownerId = _is.ColumnUuid(
      'ownerId',
      this,
    );
  }

  late final HubUpdateTable updateTable;

  late final _is.ColumnString name;

  late final _is.ColumnString slug;

  /// `owner/name` di GitHub, bila repo ada di GitHub.
  late final _is.ColumnString githubRepo;

  /// URL clone tanpa kredensial (https GitHub atau path lokal untuk dev/test).
  late final _is.ColumnString remoteUrl;

  late final _is.ColumnInt installationId;

  late final _is.ColumnString defaultBranch;

  late final _is.ColumnString headSha;

  late final _is.ColumnDateTime lastIndexedAt;

  late final _is.ColumnUuid ownerId;

  @override
  List<_is.Column> get columns => [
    id,
    name,
    slug,
    githubRepo,
    remoteUrl,
    installationId,
    defaultBranch,
    headSha,
    lastIndexedAt,
    ownerId,
  ];
}

class HubInclude extends _is.IncludeObject {
  HubInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Hub.t;
}

class HubIncludeList extends _is.IncludeList {
  HubIncludeList._({
    _is.WhereExpressionBuilder<HubTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Hub.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Hub.t;
}

class HubRepository {
  const HubRepository._();

  /// Returns a list of [Hub]s matching the given query parameters.
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
  Future<List<Hub>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<HubTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<HubTable>? orderBy,
    _is.OrderByListBuilder<HubTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Hub>(
      where: where?.call(Hub.t),
      orderBy: orderBy?.call(Hub.t),
      orderByList: orderByList?.call(Hub.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Hub]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Hub.t`.
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
  _ida.Stream<List<Hub>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<HubTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<HubTable>? orderBy,
    _is.OrderByListBuilder<HubTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Hub>(
      where: where?.call(Hub.t),
      orderBy: orderBy?.call(Hub.t),
      orderByList: orderByList?.call(Hub.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Hub] matching the given query parameters.
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
  Future<Hub?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<HubTable>? where,
    int? offset,
    _is.OrderByBuilder<HubTable>? orderBy,
    _is.OrderByListBuilder<HubTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Hub>(
      where: where?.call(Hub.t),
      orderBy: orderBy?.call(Hub.t),
      orderByList: orderByList?.call(Hub.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Hub] by its [id] or null if no such row exists.
  Future<Hub?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Hub>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Hub]s in the list and returns the inserted rows.
  ///
  /// The returned [Hub]s will have their `id` fields set.
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
  Future<List<Hub>> insert(
    _is.DatabaseSession session,
    List<Hub> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Hub>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Hub] and returns the inserted row.
  ///
  /// The returned [Hub] will have its `id` field set.
  Future<Hub> insertRow(
    _is.DatabaseSession session,
    Hub row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Hub>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Hub]s in the list and returns the resulting rows.
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
  /// The returned [Hub]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Hub>> upsert(
    _is.DatabaseSession session,
    List<Hub> rows, {
    required _is.ColumnSelections<HubTable> conflictColumns,
    _is.ColumnSelections<HubTable>? updateColumns,
    _is.WhereExpressionBuilder<HubTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Hub>(
      rows,
      conflictColumns: conflictColumns(Hub.t),
      updateColumns: updateColumns?.call(Hub.t),
      updateWhere: updateWhere?.call(Hub.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Hub] and returns the resulting row.
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
  /// The returned [Hub] will have its `id` field set.
  Future<Hub?> upsertRow(
    _is.DatabaseSession session,
    Hub row, {
    required _is.ColumnSelections<HubTable> conflictColumns,
    _is.ColumnSelections<HubTable>? updateColumns,
    _is.WhereExpressionBuilder<HubTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Hub>(
      row,
      conflictColumns: conflictColumns(Hub.t),
      updateColumns: updateColumns?.call(Hub.t),
      updateWhere: updateWhere?.call(Hub.t),
      transaction: transaction,
    );
  }

  /// Updates all [Hub]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Hub>> update(
    _is.DatabaseSession session,
    List<Hub> rows, {
    _is.ColumnSelections<HubTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Hub>(
      rows,
      columns: columns?.call(Hub.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Hub]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Hub> updateRow(
    _is.DatabaseSession session,
    Hub row, {
    _is.ColumnSelections<HubTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Hub>(
      row,
      columns: columns?.call(Hub.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Hub] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Hub?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<HubUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Hub>(
      id,
      columnValues: columnValues(Hub.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Hub]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Hub>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<HubUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<HubTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<HubTable>? orderBy,
    _is.OrderByListBuilder<HubTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Hub>(
      columnValues: columnValues(Hub.t.updateTable),
      where: where(Hub.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Hub.t),
      orderByList: orderByList?.call(Hub.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Hub]s in the list and returns the deleted rows.
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
  Future<List<Hub>> delete(
    _is.DatabaseSession session,
    List<Hub> rows, {
    _is.OrderByBuilder<HubTable>? orderBy,
    _is.OrderByListBuilder<HubTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Hub>(
      rows,
      orderBy: orderBy?.call(Hub.t),
      orderByList: orderByList?.call(Hub.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Hub].
  Future<Hub> deleteRow(
    _is.DatabaseSession session,
    Hub row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Hub>(
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
  Future<List<Hub>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<HubTable> where,
    _is.OrderByBuilder<HubTable>? orderBy,
    _is.OrderByListBuilder<HubTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Hub>(
      where: where(Hub.t),
      orderBy: orderBy?.call(Hub.t),
      orderByList: orderByList?.call(Hub.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<HubTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Hub>(
      where: where?.call(Hub.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Hub] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<HubTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Hub>(
      where: where(Hub.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
