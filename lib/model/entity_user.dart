import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

@Entity()
class EntityUser {
  // ObjectBox local ID
  @Id()
  int id = 0;

  // Mongo ObjectId
  String? mongoId;

  String? first;
  String? last;
  String? dob;
  String? gender;
  String? username;
  String? password;


  @Unique()
  String objectId = ObjectId().hexString;  //mongo id

  // todo: alternate mobile number
  // todo: id proof key
  // todo: id proof value
  // todo: address
  String? mobileNumber;
  String? alternateMobile;
  String? idProofType;
  String? idProofNumber;
  String? address;

  // e.g. SUPER_ADMIN, CASHIER
  String? role;
  String? storeId;
  bool? isActive = true;
  List<String>? permissions;

  // UTC format
  String? lastLoginAt;
  String? lastLoginDevice;
  String? lastLoginIp;
  bool? isSync = false;

  EntityUser({
    this.id = 0,
    this.mobileNumber,
    this.alternateMobile,
    this.idProofNumber,
    this.idProofType,
    this.address,
    this.mongoId,
    this.first,
    this.last,
    this.dob,
    this.gender,
    this.username,
    this.password,
    this.role,
    this.storeId,
    this.isActive = true,
    this.permissions,
    this.lastLoginAt,
    this.lastLoginDevice,
    this.lastLoginIp,
    this.isSync = false,
  });

  // Convert a Map into an EntityUser
  factory EntityUser.fromMap(Map<String, dynamic> map) {
    return EntityUser(
      id: map['id'] ?? 0,
      mobileNumber: map['mobileNumber'],
      alternateMobile: map['alternateMobile'],
      idProofNumber: map['idProofNumber'],
      idProofType: map['idProofType'],
      address: map['address'],
      mongoId: map['mongoId'] ?? map['_id'], // Handles Mongo '_id' convention
      first: map['first'],
      last: map['last'],
      dob: map['dob'],
      gender: map['gender'],
      username: map['username'],
      password: map['password'],
      role: map['role'],
      storeId: map['storeId'],
      isActive: map['isActive'] ?? true,
      permissions: map['permissions'] != null
          ? List<String>.from(map['permissions'])
          : null,
      lastLoginAt: map['lastLoginAt'],
      lastLoginDevice: map['lastLoginDevice'],
      lastLoginIp: map['lastLoginIp'],
      isSync: map['isSync'] ?? false,
    );
  }

  // Convert an EntityUser into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mobileNumber': mobileNumber,
      'alternateMobile': alternateMobile,
      'idProofNumber': idProofNumber,
      'idProofType': idProofType,
      'address': address,
      'mongoId': mongoId,
      'first': first,
      'last': last,
      'dob': dob,
      'gender': gender,
      'username': username,
      'password': password,
      'role': role,
      'storeId': storeId,
      'isActive': isActive,
      'permissions': permissions,
      'lastLoginAt': lastLoginAt,
      'lastLoginDevice': lastLoginDevice,
      'lastLoginIp': lastLoginIp,
      'isSync': isSync,
    };
  }
}
