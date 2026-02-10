import 'dart:io';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/remote/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remote;

  ProfileRepositoryImpl(this.remote);

  @override
  Future<String> uploadProfileImage(File file) {
    return remote.uploadProfileImage(file);
  }

  /// ✅ IMPLEMENTED (ERROR GONE)
  @override
  Future<ProfileEntity> getProfile() async {
    final data = await remote.fetchProfile();

    return ProfileEntity(
      id: data["id"],
      imageUrl: data["imageUrl"],
      fullName: data["fullName"],
      email: data["email"],
      className: data["className"],
    );
  }
}
