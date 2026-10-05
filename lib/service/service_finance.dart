import '../model/entity_finance_transaction.dart';
import '../objectbox.g.dart';

class ServiceFinance {
  final Box<EntityFinanceTransaction> _box;

  ServiceFinance(this._box);

  /// Save (insert or update) a transaction
  int save(EntityFinanceTransaction tx) => _box.put(tx);

  /// Get all transactions ordered by date descending.
  ///
  /// ⚡ PERFORMANCE: Uses ObjectBox query ordering instead of
  ///    Dart-side `List.sort()` which is O(n log n) in memory.
  List<EntityFinanceTransaction> getAll() {
    return _box
        .query()
        .order(EntityFinanceTransaction_.dateUtcMs, flags: Order.descending)
        .build()
        .find();
  }

  /// Filter by type (expense / borrow / lend).
  ///
  /// ⚡ PERFORMANCE: Uses ObjectBox condition instead of
  ///    `getAll().where(...)` which loads ALL records into memory first.
  List<EntityFinanceTransaction> getByType(String type) {
    return _box
        .query(EntityFinanceTransaction_.type.equals(type))
        .order(EntityFinanceTransaction_.dateUtcMs, flags: Order.descending)
        .build()
        .find();
  }

  /// Filter by date range using dateUtcMs (milliseconds since epoch).
  ///
  /// ⚡ PERFORMANCE: Uses ObjectBox between() condition instead of
  ///    loading all records and filtering in Dart.
  List<EntityFinanceTransaction> getByDateRange(
    String fromDate,
    String toDate,
  ) {
    // Convert date strings to UTC ms range for ObjectBox query.
    // Since we store createdDate as a string, we use string comparison.
    final q = _box
        .query(EntityFinanceTransaction_.createdDate
            .greaterOrEqual(fromDate)
            .and(EntityFinanceTransaction_.createdDate.lessOrEqual(toDate)))
        .order(EntityFinanceTransaction_.dateUtcMs, flags: Order.descending)
        .build();
    final results = q.find();
    q.close();
    return results;
  }

  /// Filter by type AND date range.
  ///
  /// ⚡ PERFORMANCE: Single combined ObjectBox query instead of
  ///    chaining getAll() → where(date) → where(type).
  List<EntityFinanceTransaction> getByTypeAndDateRange(
    String type,
    String fromDate,
    String toDate,
  ) {
    final q = _box
        .query(EntityFinanceTransaction_.type.equals(type).and(
              EntityFinanceTransaction_.createdDate
                  .greaterOrEqual(fromDate)
                  .and(EntityFinanceTransaction_.createdDate
                      .lessOrEqual(toDate)),
            ))
        .order(EntityFinanceTransaction_.dateUtcMs, flags: Order.descending)
        .build();
    final results = q.find();
    q.close();
    return results;
  }

  /// ⚡ HIGH-PERFORMANCE: Paginated transactions query with native offset and limit.
  /// Does NOT load the entire database into memory.
  ({List<EntityFinanceTransaction> items, int totalCount}) getPaginated({
    String type = 'all',
    String? fromDate,
    String? toDate,
    int offset = 0,
    int limit = 20,
  }) {
    Condition<EntityFinanceTransaction>? cond;

    if (type != 'all') {
      cond = EntityFinanceTransaction_.type.equals(type);
    }

    if (fromDate != null && toDate != null) {
      final dateCond = EntityFinanceTransaction_.createdDate
          .greaterOrEqual(fromDate)
          .and(EntityFinanceTransaction_.createdDate.lessOrEqual(toDate));
      cond = cond == null ? dateCond : cond.and(dateCond);
    }

    final queryBuilder = _box.query(cond)
      ..order(EntityFinanceTransaction_.dateUtcMs, flags: Order.descending);

    final q = queryBuilder.build();
    final totalCount = q.count();
    q
      ..offset = offset
      ..limit = limit;
    final results = q.find();
    q.close();

    return (items: results, totalCount: totalCount);
  }

  /// ⚡ HIGH-PERFORMANCE: Computes sum of amounts directly inside ObjectBox C engine
  /// without allocating and deserializing thousands of Dart entity objects.
  double getSumByType(String type, {String? fromDate, String? toDate}) {
    Condition<EntityFinanceTransaction> cond =
        EntityFinanceTransaction_.type.equals(type);

    if (fromDate != null && toDate != null) {
      cond = cond.and(
        EntityFinanceTransaction_.createdDate
            .greaterOrEqual(fromDate)
            .and(EntityFinanceTransaction_.createdDate.lessOrEqual(toDate)),
      );
    }

    final q = _box.query(cond).build();
    final propQuery = q.property(EntityFinanceTransaction_.amount);
    final sum = propQuery.sum();
    q.close();
    return sum;
  }

  bool delete(int id) => _box.remove(id);
}
