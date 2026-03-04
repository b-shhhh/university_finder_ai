import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:Uniguide/features/auth/domain/entities/auth_entity.dart';
import 'package:Uniguide/features/auth/domain/entities/auth_response.dart';
import 'package:Uniguide/features/auth/domain/repositories/auth_repository.dart';
import 'package:Uniguide/features/auth/domain/usecases/login_usecase.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late LoginUseCase useCase;

  const email = 'test@example.com';
  const password = 'P@ssw0rd!';
  final user = AuthEntity(
    id: '1',
    fullName: 'Test User',
    email: email,
    phone: '123456789',
  );

  setUp(() {
    repository = _MockAuthRepository();
    useCase = LoginUseCase(repository: repository);
  });

  group('LoginUseCase', () {
    test('returns repository result on success', () async {
      final expected = AuthResponse.success(user, message: 'Logged in');
      when(() => repository.loginUser(email, password)).thenAnswer((_) async => expected);

      final result = await useCase.execute(email, password);

      expect(result.success, isTrue);
      expect(result.user, expected.user);
      expect(result.message, 'Logged in');
    });

    test('passes correct credentials to repository', () async {
      when(() => repository.loginUser(any(), any()))
          .thenAnswer((_) async => AuthResponse.success(user));

      await useCase.execute(email, password);

      verify(() => repository.loginUser(email, password)).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('propagates exceptions from repository', () async {
      when(() => repository.loginUser(email, password))
          .thenThrow(Exception('network down'));

      expect(
        () => useCase.execute(email, password),
        throwsA(isA<Exception>()),
      );
    });

    test('allows multiple calls and keeps repository invocations isolated', () async {
      when(() => repository.loginUser(any(), any()))
          .thenAnswer((_) async => AuthResponse.success(user));

      await useCase.execute(email, password);
      await useCase.execute('another@example.com', 'pass123');

      verify(() => repository.loginUser(email, password)).called(1);
      verify(() => repository.loginUser('another@example.com', 'pass123')).called(1);
    });

    test('supports different messages returned by repository', () async {
      final expected = AuthResponse.success(user, message: 'Custom message');
      when(() => repository.loginUser(email, password)).thenAnswer((_) async => expected);

      final result = await useCase.execute(email, password);

      expect(result.message, 'Custom message');
    });
  });
}
