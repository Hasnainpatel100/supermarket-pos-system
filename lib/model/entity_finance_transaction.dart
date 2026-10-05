import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

@Entity()
class EntityFinanceTransaction {
  @Id()
  int id = 0;

  @Index()
  String? type;
  // expense, borrow, lend

  @Index()
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

  @Index()
  int? dateUtcMs;

  /// Date stored as yyyy-MM-dd (no time component)
  @Index()
  String? createdDate;
}
