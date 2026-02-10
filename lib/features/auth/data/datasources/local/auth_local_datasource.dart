import 'package:hive/hive.dart';
import '../../models/auth_hive_model.dart';

class AuthLocalDataSource {
  static const String _boxName = 'usersBox';

  /// Registers a new user locally in Hive
  Future<void> registerUser(AuthHiveModel user) async {
    final box = await Hive.openBox<AuthHiveModel>(_boxName);
    if (box.containsKey(user.email)) {
      throw Exception('User with this email already exists');
    }
    await box.put(user.email, user);
  }

  /// Fetches user by email and password for login
  Future<AuthHiveModel?> loginUser(String email, String password) async {
    final box = await Hive.openBox<AuthHiveModel>(_boxName);
    final user = box.get(email);

    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }

  /// Optional: get user by email (e.g., for profile)
  Future<AuthHiveModel?> getUserByEmail(String email) async {
    final box = await Hive.openBox<AuthHiveModel>(_boxName);
    return box.get(email);
  }

  /// Optional: update user
  Future<void> updateUser(AuthHiveModel user) async {
    final box = await Hive.openBox<AuthHiveModel>(_boxName);
    await box.put(user.email, user);
  }

  /// Optional: delete user
  Future<void> deleteUser(String email) async {
    final box = await Hive.openBox<AuthHiveModel>(_boxName);
    await box.delete(email);
  }
}
