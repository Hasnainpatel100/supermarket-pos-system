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

  int? createdAtUtcMs;

  EntityCustomer({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.address,
    this.createdAtUtcMs,
  });
}
