import 'package:drift/drift.dart';
import 'package:drift/backends.dart';

/// No-op executor for web — the app is purely API-driven on web.
/// All db operations are guarded with `if (!kIsWeb)` in providers.
QueryExecutor getExecutor() => _WebStubExecutor();

class _WebStubExecutor extends QueryExecutor {
  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async => true;

  @override
  Future<List<Map<String, Object?>>> runSelect(
          String statement, List<Object?> args) async =>
      [];

  @override
  Future<int> runInsert(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runDelete(String statement, List<Object?> args) async => 0;

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {}

  @override
  Future<void> runBatched(BatchedStatements statements) async {}

  @override
  TransactionExecutor beginTransaction() => _WebStubTransaction(this);

  @override
  QueryExecutor beginExclusive() => this;
}

class _WebStubTransaction extends _WebStubExecutor
    implements TransactionExecutor {
  _WebStubTransaction(QueryExecutor db);

  @override
  Future<void> rollback() async {}

  @override
  Future<void> send() async {}

  @override
  bool get supportsNestedTransactions => false;
}
