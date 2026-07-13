import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

@Entity()
class EntitySupplier {
  @Id()
  int? id;

  @Unique()
  String? supplierCode;
  
  @Unique()
  String? mongoId;


  @Unique()
  String objectId = ObjectId().hexString;  //mongo id


  String? name;
  String? contactPerson;
  String? phone;
  String? email;
  String? address;
  String? gstNumber;

  bool? isActive;

  /// ⭐ PAYMENT CACHE — sum of amountDue across all non-cancelled purchases
  /// Updated every time a payment is recorded or a PO is created/cancelled.
  double? totalOutstanding;


  /// ⭐ TIMESTAMP FIELDS
  int? createdAtUtcMs;
  int? createdDate;

  int? updatedAtUtcMs;
  int? updatedDate;

  EntitySupplier({
    this.id,
    this.supplierCode,
    this.mongoId,
    this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.gstNumber,
    this.isActive = true,
    this.totalOutstanding=0,
    this.createdAtUtcMs,
    this.createdDate,
    this.updatedAtUtcMs,
    this.updatedDate,
  });
}