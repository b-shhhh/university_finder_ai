import 'package:hive/hive.dart';
part 'auth_hive_model.g.dart';

@HiveType(typeId: 0)
class AuthHiveModel extends HiveObject {
  @HiveField(0)
  String fullName;

  @HiveField(1)
  String email;

  @HiveField(2)
  String password;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String education;

  AuthHiveModel({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.education,
  });
}
