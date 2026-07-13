import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

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


  @Unique()
  String objectId = ObjectId().hexString;  //mongo id

  double? amount;

  bool? isDebit;
  // true = debit
  // false = credit

  String? note;

  int? dateUtcMs;

  /// Date stored as yyyy-MM-dd (no time component)
  String? createdDate;
}
