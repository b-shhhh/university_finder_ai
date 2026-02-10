import 'dart:io';
import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<String> uploadProfileImage(File file);

  Future<ProfileEntity> getProfile();
}
