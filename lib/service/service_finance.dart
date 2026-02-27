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

  bool delete(int id) => _box.remove(id);
}
