/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'package:whisker_server/src/generated/hub/hub.dart' as _i4ennidr;
import 'backup/backup_record.dart' as _ih5wr8up;
import 'doc/document_link.dart' as _iyowq5et;
import 'doc/dto/commit_request.dart' as _iug8u9w8;
import 'doc/dto/commit_result.dart' as _i0m3016f;
import 'doc/dto/doc_content.dart' as _iy626nui;
import 'doc/dto/doc_summary.dart' as _ip1t3e4d;
import 'doc/dto/history_entry.dart' as _ifw083n3;
import 'doc/dto/search_hit.dart' as _icfkkuzr;
import 'doc/hub_document.dart' as _ihi6zqwq;
import 'hub/hub.dart' as _ix22b1vy;
import 'hub/hub_change.dart' as _innk4gsl;
import 'hub/hub_member.dart' as _iv7a87od;
import 'hub/whisker_exception.dart' as _i5k8hrwr;
export 'backup/backup_record.dart';
export 'doc/document_link.dart';
export 'doc/dto/commit_request.dart';
export 'doc/dto/commit_result.dart';
export 'doc/dto/doc_content.dart';
export 'doc/dto/doc_summary.dart';
export 'doc/dto/history_entry.dart';
export 'doc/dto/search_hit.dart';
export 'doc/hub_document.dart';
export 'hub/hub.dart';
export 'hub/hub_change.dart';
export 'hub/hub_member.dart';
export 'hub/whisker_exception.dart';

class Protocol extends _is.DatabaseSerializationManager
    implements _is.DatabaseProtocolDeserializationProvider {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  @override
  _is.ProtocolDeserialization get deserializationMetadata =>
      _is.ProtocolDeserialization.cached(
        this,
        types: const [
          _is.getType<_ih5wr8up.BackupRecord>,
          _is.getType<_iyowq5et.DocumentLink>,
          _is.getType<_iug8u9w8.CommitRequest>,
          _is.getType<_i0m3016f.CommitResult>,
          _is.getType<_iy626nui.DocContent>,
          _is.getType<_ip1t3e4d.DocSummary>,
          _is.getType<_ifw083n3.HistoryEntry>,
          _is.getType<_icfkkuzr.SearchHit>,
          _is.getType<_ihi6zqwq.HubDocument>,
          _is.getType<_ix22b1vy.Hub>,
          _is.getType<_innk4gsl.HubChange>,
          _is.getType<_iv7a87od.HubMember>,
          _is.getType<_i5k8hrwr.WhiskerException>,
          _is.getType<_ih5wr8up.BackupRecord?>,
          _is.getType<_iyowq5et.DocumentLink?>,
          _is.getType<_iug8u9w8.CommitRequest?>,
          _is.getType<_i0m3016f.CommitResult?>,
          _is.getType<_iy626nui.DocContent?>,
          _is.getType<_ip1t3e4d.DocSummary?>,
          _is.getType<_ifw083n3.HistoryEntry?>,
          _is.getType<_icfkkuzr.SearchHit?>,
          _is.getType<_ihi6zqwq.HubDocument?>,
          _is.getType<_ix22b1vy.Hub?>,
          _is.getType<_innk4gsl.HubChange?>,
          _is.getType<_iv7a87od.HubMember?>,
          _is.getType<_i5k8hrwr.WhiskerException?>,
          _is.getType<List<String>>,
          _is.getType<List<_i4ennidr.Hub>>,
        ],
        modules: const [
          _iais.Protocol.new,
          _iacs.Protocol.new,
          _isp.Protocol.new,
        ],
        classNames: const [
          'BackupRecord',
          'DocumentLink',
          'CommitRequest',
          'CommitResult',
          'DocContent',
          'DocSummary',
          'HistoryEntry',
          'SearchHit',
          'HubDocument',
          'Hub',
          'HubChange',
          'HubMember',
          'WhiskerException',
        ],
      );

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'backup',
      dartName: 'BackupRecord',
      schema: 'public',
      module: 'whisker',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'hubId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'objectKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sizeBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'error',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'document',
      dartName: 'HubDocument',
      schema: 'public',
      module: 'whisker',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'hubId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'path',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'area',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'type',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'frontmatter',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'tags',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'blobSha',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'lastCommitSha',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'document_hub_path_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'hubId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'path',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'document_link',
      dartName: 'DocumentLink',
      schema: 'public',
      module: 'whisker',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'fromDocId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'hubId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'toPath',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'toDocId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'document_link_from_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fromDocId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'document_link_to_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'toDocId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'hub',
      dartName: 'Hub',
      schema: 'public',
      module: 'whisker',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'slug',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'githubRepo',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'remoteUrl',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'installationId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'defaultBranch',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'main\'',
        ),
        _isp.ColumnDefinition(
          name: 'headSha',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'lastIndexedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'ownerId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'hub_slug_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'slug',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'hub_member',
      dartName: 'HubMember',
      schema: 'public',
      module: 'whisker',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'hubId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'role',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'hub_member_unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'hubId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._iais.Protocol.targetTableDefinitions,
    ..._iacs.Protocol.targetTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) =>
      _is.ProtocolDeserialization.readClassName(data);

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    final rawDataClassName = _is.ProtocolDeserialization.readClassName(data);
    final dataClassName = rawDataClassName;
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _is.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _ih5wr8up.BackupRecord) {
      return _ih5wr8up.BackupRecord.fromJson(data) as T;
    }
    if (t == _iyowq5et.DocumentLink) {
      return _iyowq5et.DocumentLink.fromJson(data) as T;
    }
    if (t == _iug8u9w8.CommitRequest) {
      return _iug8u9w8.CommitRequest.fromJson(data) as T;
    }
    if (t == _i0m3016f.CommitResult) {
      return _i0m3016f.CommitResult.fromJson(data) as T;
    }
    if (t == _iy626nui.DocContent) {
      return _iy626nui.DocContent.fromJson(data) as T;
    }
    if (t == _ip1t3e4d.DocSummary) {
      return _ip1t3e4d.DocSummary.fromJson(data) as T;
    }
    if (t == _ifw083n3.HistoryEntry) {
      return _ifw083n3.HistoryEntry.fromJson(data) as T;
    }
    if (t == _icfkkuzr.SearchHit) {
      return _icfkkuzr.SearchHit.fromJson(data) as T;
    }
    if (t == _ihi6zqwq.HubDocument) {
      return _ihi6zqwq.HubDocument.fromJson(data) as T;
    }
    if (t == _ix22b1vy.Hub) {
      return _ix22b1vy.Hub.fromJson(data) as T;
    }
    if (t == _innk4gsl.HubChange) {
      return _innk4gsl.HubChange.fromJson(data) as T;
    }
    if (t == _iv7a87od.HubMember) {
      return _iv7a87od.HubMember.fromJson(data) as T;
    }
    if (t == _i5k8hrwr.WhiskerException) {
      return _i5k8hrwr.WhiskerException.fromJson(data) as T;
    }
    if (t == _is.getType<_ih5wr8up.BackupRecord?>()) {
      return (data != null ? _ih5wr8up.BackupRecord.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iyowq5et.DocumentLink?>()) {
      return (data != null ? _iyowq5et.DocumentLink.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iug8u9w8.CommitRequest?>()) {
      return (data != null ? _iug8u9w8.CommitRequest.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i0m3016f.CommitResult?>()) {
      return (data != null ? _i0m3016f.CommitResult.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iy626nui.DocContent?>()) {
      return (data != null ? _iy626nui.DocContent.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ip1t3e4d.DocSummary?>()) {
      return (data != null ? _ip1t3e4d.DocSummary.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ifw083n3.HistoryEntry?>()) {
      return (data != null ? _ifw083n3.HistoryEntry.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_icfkkuzr.SearchHit?>()) {
      return (data != null ? _icfkkuzr.SearchHit.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ihi6zqwq.HubDocument?>()) {
      return (data != null ? _ihi6zqwq.HubDocument.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ix22b1vy.Hub?>()) {
      return (data != null ? _ix22b1vy.Hub.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_innk4gsl.HubChange?>()) {
      return (data != null ? _innk4gsl.HubChange.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iv7a87od.HubMember?>()) {
      return (data != null ? _iv7a87od.HubMember.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i5k8hrwr.WhiskerException?>()) {
      return (data != null ? _i5k8hrwr.WhiskerException.fromJson(data) : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i4ennidr.Hub>) {
      return (data as List).map((e) => deserialize<_i4ennidr.Hub>(e)).toList()
          as T;
    }
    final modules = deserializationMetadata.modulesForDeserialization(
      t,
      className: rawDataClassName,
    );
    for (final module in modules) {
      try {
        return module.deserialize<T>(data, t);
      } on _is.DeserializationTypeNotFoundException catch (_) {}
    }

    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _ih5wr8up.BackupRecord => 'BackupRecord',
      _iyowq5et.DocumentLink => 'DocumentLink',
      _iug8u9w8.CommitRequest => 'CommitRequest',
      _i0m3016f.CommitResult => 'CommitResult',
      _iy626nui.DocContent => 'DocContent',
      _ip1t3e4d.DocSummary => 'DocSummary',
      _ifw083n3.HistoryEntry => 'HistoryEntry',
      _icfkkuzr.SearchHit => 'SearchHit',
      _ihi6zqwq.HubDocument => 'HubDocument',
      _ix22b1vy.Hub => 'Hub',
      _innk4gsl.HubChange => 'HubChange',
      _iv7a87od.HubMember => 'HubMember',
      _i5k8hrwr.WhiskerException => 'WhiskerException',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('whisker.', '');
    }

    switch (data) {
      case _ih5wr8up.BackupRecord():
        return 'BackupRecord';
      case _iyowq5et.DocumentLink():
        return 'DocumentLink';
      case _iug8u9w8.CommitRequest():
        return 'CommitRequest';
      case _i0m3016f.CommitResult():
        return 'CommitResult';
      case _iy626nui.DocContent():
        return 'DocContent';
      case _ip1t3e4d.DocSummary():
        return 'DocSummary';
      case _ifw083n3.HistoryEntry():
        return 'HistoryEntry';
      case _icfkkuzr.SearchHit():
        return 'SearchHit';
      case _ihi6zqwq.HubDocument():
        return 'HubDocument';
      case _ix22b1vy.Hub():
        return 'Hub';
      case _innk4gsl.HubChange():
        return 'HubChange';
      case _iv7a87od.HubMember():
        return 'HubMember';
      case _i5k8hrwr.WhiskerException():
        return 'WhiskerException';
    }
    className = _iais.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'BackupRecord') {
      return deserialize<_ih5wr8up.BackupRecord>(data['data']);
    }
    if (dataClassName == 'DocumentLink') {
      return deserialize<_iyowq5et.DocumentLink>(data['data']);
    }
    if (dataClassName == 'CommitRequest') {
      return deserialize<_iug8u9w8.CommitRequest>(data['data']);
    }
    if (dataClassName == 'CommitResult') {
      return deserialize<_i0m3016f.CommitResult>(data['data']);
    }
    if (dataClassName == 'DocContent') {
      return deserialize<_iy626nui.DocContent>(data['data']);
    }
    if (dataClassName == 'DocSummary') {
      return deserialize<_ip1t3e4d.DocSummary>(data['data']);
    }
    if (dataClassName == 'HistoryEntry') {
      return deserialize<_ifw083n3.HistoryEntry>(data['data']);
    }
    if (dataClassName == 'SearchHit') {
      return deserialize<_icfkkuzr.SearchHit>(data['data']);
    }
    if (dataClassName == 'HubDocument') {
      return deserialize<_ihi6zqwq.HubDocument>(data['data']);
    }
    if (dataClassName == 'Hub') {
      return deserialize<_ix22b1vy.Hub>(data['data']);
    }
    if (dataClassName == 'HubChange') {
      return deserialize<_innk4gsl.HubChange>(data['data']);
    }
    if (dataClassName == 'HubMember') {
      return deserialize<_iv7a87od.HubMember>(data['data']);
    }
    if (dataClassName == 'WhiskerException') {
      return deserialize<_i5k8hrwr.WhiskerException>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      return _iais.Protocol().deserializeByClassName({
        ...data,
        'className': dataClassName.substring(19),
      });
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      return _iacs.Protocol().deserializeByClassName({
        ...data,
        'className': dataClassName.substring(20),
      });
    }
    if (dataClassName.startsWith('serverpod.')) {
      return _isp.Protocol().deserializeByClassName({
        ...data,
        'className': dataClassName.substring(10),
      });
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iais.Protocol().registerHostProtocol('whisker', this);
    _iacs.Protocol().registerHostProtocol('whisker', this);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _iais.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _iacs.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _ih5wr8up.BackupRecord:
        return _ih5wr8up.BackupRecord.t;
      case _iyowq5et.DocumentLink:
        return _iyowq5et.DocumentLink.t;
      case _ihi6zqwq.HubDocument:
        return _ihi6zqwq.HubDocument.t;
      case _ix22b1vy.Hub:
        return _ix22b1vy.Hub.t;
      case _iv7a87od.HubMember:
        return _iv7a87od.HubMember.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'whisker';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iais.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
