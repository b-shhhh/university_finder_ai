import 'package:hive/hive.dart';

class HiveService {
  Future<Box> openBox(String name) async {
    return await Hive.openBox(name);
  }

  Future<void> put(Box box, String key, dynamic value) async {
    await box.put(key, value);
  }

  dynamic get(Box box, String key) {
    return box.get(key);
  }

  Future<void> clear(Box box) async {
    await box.clear();
  }
}
