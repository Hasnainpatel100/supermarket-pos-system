import 'package:objectbox/objectbox.dart';

/// A named tax preset that the user can create and reuse (e.g. SGST 9%, CGST 9%)
@Entity()
class EntityTax {
  @Id()
  int? id;

  String? name; // e.g. "SGST", "CGST", "VAT"
  double? rate; // e.g. 9.0, 18.0

  EntityTax({this.id, this.name, this.rate});
}
