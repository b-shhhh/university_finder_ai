import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/upload_profile_image.dart';
import '../view model/profile_view_model.dart';
import '../state/profile_state.dart';
import 'package:flutter_riverpod/legacy.dart';


final uploadProfileImageUseCaseProvider = Provider((ref) {
  return UploadProfileImage(uploadUrl: 'http://localhost:3000/upload');
});

final profileViewModelProvider = StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  final uploadUseCase = ref.read(uploadProfileImageUseCaseProvider);
  return ProfileViewModel(uploadUseCase: uploadUseCase);
});
