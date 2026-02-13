import 'dart:io';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/remote/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remote;

  ProfileRepositoryImpl(this.remote);

  @override
  Future<String> uploadProfileImage(File file) async {
    final res = await remote.uploadProfileImage(file);
    final data = res['data'] as Map<String, dynamic>? ?? res;
    return data['profilePic']?.toString() ?? '';
  }

  /// ✅ IMPLEMENTED (ERROR GONE)
  @override
  Future<ProfileEntity> getProfile() async {
    final data = await remote.fetchProfile();
    final user = data['data'] as Map<String, dynamic>? ?? data;

    return ProfileEntity(
      id: user["id"]?.toString(),
      imageUrl: user["profilePic"]?.toString(),
      fullName: user["fullName"]?.toString(),
      email: user["email"]?.toString(),
      className: user["className"]?.toString(),
    );
  }
}
