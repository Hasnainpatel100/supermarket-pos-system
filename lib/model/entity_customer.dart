import 'package:objectbox/objectbox.dart';

@Entity()
class EntityCustomer {
  @Id()
  int? id;

  String? name;

  @Index()
  String? phone;

  String? email;
  String? address;
  String? city;
  String? state;
  String? zipCode;
  String? notes;

  bool? isActive;

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
    this.createdAtUtcMs,
    this.updatedAtUtcMs,
  });
}
