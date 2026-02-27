import 'package:objectbox/objectbox.dart';

@Entity()
class EntityFinanceTransaction {
  @Id()
  int id = 0;

  String? type;
  // expense, borrow, lend

  String? category;
  // transportation, petrol, servicing

  String? personName;
  // customer / vendor / person

  double? amount;

  bool? isDebit;
  // true = debit
  // false = credit

  String? note;

  int? dateUtcMs;
}