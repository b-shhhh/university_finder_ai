import 'package:hive/hive.dart';
import '../models/auth_hive_model.dart';
import 'auth_repository.dart';
import '../../domain/entities/auth_entity.dart';

class AuthRepositoryImpl implements AuthRepository {
  final String hiveBoxName = 'usersBox';

  @override
  Future<void> registerUser(AuthEntity user) async {
    final box = await Hive.openBox<AuthHiveModel>(hiveBoxName);
    final hiveUser = AuthHiveModel(
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      password: user.password,
      phone: user.phone,
      education: user.education,
    );
    await box.put(user.email, hiveUser);
  }

  @override
  Future<AuthEntity?> loginUser(String email, String password) async {
    final box = await Hive.openBox<AuthHiveModel>(hiveBoxName);
    final hiveUser = box.get(email);
    if (hiveUser != null && hiveUser.password == password) {
      return AuthEntity(
        firstName: hiveUser.firstName,
        lastName: hiveUser.lastName,
        email: hiveUser.email,
        password: hiveUser.password,
        phone: hiveUser.phone,
        education: hiveUser.education,
      );
    }
    return null;
  }
}
