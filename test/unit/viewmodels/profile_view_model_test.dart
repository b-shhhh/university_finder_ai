import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:Uniguide/features/dashboard/domain/usecases/upload_profile_image.dart';
import 'package:Uniguide/features/dashboard/presentation/view model/profile_view_model.dart';

class _MockUploadProfileImage extends Mock implements UploadProfileImage {}

void main() {
  late _MockUploadProfileImage uploadUseCase;
  late ProfileViewModel viewModel;
  late File tempFile;

  setUp(() {
    uploadUseCase = _MockUploadProfileImage();
    viewModel = ProfileViewModel(uploadUseCase: uploadUseCase);

    final dir = Directory.systemTemp.createTempSync('profile_test');
    tempFile = File('${dir.path}/avatar.png')..writeAsStringSync('image-bytes');
  });

  tearDown(() {
    if (tempFile.existsSync()) {
      tempFile.parent.deleteSync(recursive: true);
    }
  });

  group('ProfileViewModel', () {
    test('starts with default state', () {
      final state = viewModel.state;
      expect(state.isLoading, isFalse);
      expect(state.imageUrl, isNull);
      expect(state.localImagePath, isNull);
      expect(state.errorMessage, isNull);
    });

    test('sets loading true immediately, then false after success', () async {
      when(() => uploadUseCase(tempFile)).thenAnswer((_) async => 'https://cdn/img.png');

      final future = viewModel.uploadProfileImage(tempFile);
      expect(viewModel.state.isLoading, isTrue);

      await future;
      expect(viewModel.state.isLoading, isFalse);
    });

    test('uploads image and stores urls on success', () async {
      when(() => uploadUseCase(tempFile)).thenAnswer((_) async => 'https://cdn/profile.png');

      await viewModel.uploadProfileImage(tempFile);

      final state = viewModel.state;
      expect(state.imageUrl, 'https://cdn/profile.png');
      expect(state.localImagePath, tempFile.path);
      expect(state.errorMessage, isNull);
    });

    test('captures errors and resets loading', () async {
      when(() => uploadUseCase(tempFile)).thenThrow(Exception('upload failed'));

      await viewModel.uploadProfileImage(tempFile);

      final state = viewModel.state;
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('upload failed'));
      expect(state.imageUrl, isNull);
    });

    test('keeps previous imageUrl when a later upload fails', () async {
      when(() => uploadUseCase(tempFile)).thenAnswer((_) async => 'https://cdn/first.png');
      await viewModel.uploadProfileImage(tempFile);

      when(() => uploadUseCase(tempFile)).thenThrow(Exception('network error'));
      await viewModel.uploadProfileImage(tempFile);

      final state = viewModel.state;
      expect(state.imageUrl, 'https://cdn/first.png');
      expect(state.errorMessage, contains('network error'));
    });
  });
}
