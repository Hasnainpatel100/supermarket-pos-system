import 'package:objectbox/objectbox.dart';

@Entity()
class EntitySupplier {
  @Id()
  int? id;

  @Unique()
  String? supplierCode;
  
  @Unique()
  String? mongoId;

  String? name;
  String? contactPerson;
  String? phone;
  String? email;
  String? address;
  String? gstNumber;

  bool? isActive;

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
    this.createdAtUtcMs,
    this.createdDate,
    this.updatedAtUtcMs,
    this.updatedDate,
  });
}