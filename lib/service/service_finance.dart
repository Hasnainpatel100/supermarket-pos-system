import '../model/entity_finance_transaction.dart';
import '../objectbox.g.dart';

class ServiceFinance {
  final Box<EntityFinanceTransaction> _box;

  ServiceFinance(this._box);

  /// Save (insert or update) a transaction
  int save(EntityFinanceTransaction tx) => _box.put(tx);

  /// Get all transactions ordered by date descending
  List<EntityFinanceTransaction> getAll() {
    final all = _box.getAll();
    all.sort((a, b) => (b.dateUtcMs ?? 0).compareTo(a.dateUtcMs ?? 0));
    return all;
  }

  /// Filter by type (expense / borrow / lend)
  List<EntityFinanceTransaction> getByType(String type) {
    return getAll().where((t) => t.type == type).toList();
  }

  /// Filter by date range using createdDate string (yyyy-MM-dd)
  List<EntityFinanceTransaction> getByDateRange(
    String fromDate,
    String toDate,
  ) {
    return getAll().where((t) {
      final d = t.createdDate;
      if (d == null) return false;
      return d.compareTo(fromDate) >= 0 && d.compareTo(toDate) <= 0;
    }).toList();
  }

  /// Filter by type AND date range
  List<EntityFinanceTransaction> getByTypeAndDateRange(
    String type,
    String fromDate,
    String toDate,
  ) {
    return getByDateRange(
      fromDate,
      toDate,
    ).where((t) => t.type == type).toList();
  }

  bool delete(int id) => _box.remove(id);
}
