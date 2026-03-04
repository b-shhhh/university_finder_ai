import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:Uniguide/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:Uniguide/features/auth/domain/entities/auth_entity.dart';
import 'package:Uniguide/features/auth/domain/entities/auth_response.dart';
import 'package:Uniguide/features/auth/presentation/view_model/auth_view_model.dart';

class _MockAuthRepositoryImpl extends Mock implements AuthRepositoryImpl {}

void main() {
  late _MockAuthRepositoryImpl repository;
  late AuthViewModel viewModel;

  final user = AuthEntity(
    id: '1',
    fullName: 'Test User',
    email: 'user@example.com',
    phone: '123',
    password: 'Secret123',
  );

  setUp(() {
    repository = _MockAuthRepositoryImpl();
    viewModel = AuthViewModel(repository: repository);
  });

  group('AuthViewModel', () {
    test('starts with default state', () {
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.user, isNull);
      expect(viewModel.errorMessage, isNull);
    });

    test('registerUser sets user on success and clears errors', () async {
      when(() => repository.registerUser(user))
          .thenAnswer((_) async => AuthResponse.success(user, message: 'ok'));

      final response = await viewModel.registerUser(user);

      expect(response.success, isTrue);
      expect(viewModel.user, isNotNull);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isLoading, isFalse);
      verify(() => repository.registerUser(user)).called(1);
    });

    test('registerUser captures failure and stops loading', () async {
      when(() => repository.registerUser(user)).thenThrow(Exception('fail'));

      final response = await viewModel.registerUser(user);

      expect(response.success, isFalse);
      expect(viewModel.errorMessage, contains('fail'));
      expect(viewModel.user, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('loginUser sets user on success', () async {
      when(() => repository.loginUser(user.email, user.password ?? ''))
          .thenAnswer((_) async => AuthResponse.success(user));

      final response = await viewModel.loginUser(user.email, user.password ?? '');

      expect(response.success, isTrue);
      expect(viewModel.user?.email, user.email);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isLoading, isFalse);
      verify(() => repository.loginUser(user.email, user.password ?? '')).called(1);
    });

    test('loginUser captures error and resets loading', () async {
      when(() => repository.loginUser(user.email, any())).thenThrow(Exception('bad creds'));

      final response = await viewModel.loginUser(user.email, 'wrong');

      expect(response.success, isFalse);
      expect(viewModel.errorMessage, contains('bad creds'));
      expect(viewModel.user, isNull);
      expect(viewModel.isLoading, isFalse);
    });
  });
}
