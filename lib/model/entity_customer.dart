import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

@Entity()
class EntityCustomer {
  @Id()
  int? id;

  String? name;

  @Index()
  String? phone;


  @Unique()
  String objectId = ObjectId().hexString;  //mongo id

  String? email;
  String? address;
  String? city;
  String? state;
  String? zipCode;
  String? notes;

  bool? isActive;
  bool? isVip;

  int? createdAtUtcMs;
  int? updatedAtUtcMs;

  EntityCustomer({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.notes,
    this.isActive = true,
    this.isVip = false,
    this.createdAtUtcMs,
    this.updatedAtUtcMs,
  });
}
