import 'package:hive/hive.dart';

part 'business_profile.g.dart';

@HiveType(typeId: 0)
class BusinessProfile extends HiveObject {
  @HiveField(0)
  String businessName;

  @HiveField(1)
  String address;

  @HiveField(2)
  String gstin;

  @HiveField(3)
  String email;

  @HiveField(4)
  String phone;

  @HiveField(5)
  String? logoPath;

  @HiveField(6)
  String? signaturePath;

  @HiveField(7)
  String? bankName;

  @HiveField(8)
  String? accountNumber;

  @HiveField(9)
  String? ifscCode;

  @HiveField(10)
  String? branchName;

  BusinessProfile({
    required this.businessName,
    required this.address,
    required this.gstin,
    required this.email,
    required this.phone,
    this.logoPath,
    this.signaturePath,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.branchName,
  });
}
