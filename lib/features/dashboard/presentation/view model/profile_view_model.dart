import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/upload_profile_image.dart';
import '../state/profile_state.dart';
import 'package:flutter_riverpod/legacy.dart';


class ProfileViewModel extends StateNotifier<ProfileState> {
  final UploadProfileImage uploadUseCase;

  ProfileViewModel({required this.uploadUseCase}) : super(ProfileState());

  Future<void> uploadProfileImage(File image) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final imageUrl = await uploadUseCase(image);
      state = state.copyWith(
        isLoading: false,
        imageUrl: imageUrl,
        localImagePath: image.path,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
