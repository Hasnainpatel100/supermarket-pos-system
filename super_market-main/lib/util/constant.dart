import '../enums/enum_user_role.dart';

class Constant {
  static List<String> listGender = const ['Male', 'Female', 'Other', 'Not to Share'];


  static List<String> listProofType = const [
    "Aadhaar Card",
    "PAN Card",
    "Voter ID",
    "Passport",
    "Driving License",
    "Ration Card",
    "Employee ID",
    "Student ID",
    "Other Government ID",
  ];



  static List<String> listUserRole = [
    EnumUserRole.superAdmin.name,
    EnumUserRole.storeManager.name,
    EnumUserRole.cashier.name,
    EnumUserRole.inventoryClerk.name,
    EnumUserRole.accountant.name,
    EnumUserRole.auditor.name,
  ];
}
