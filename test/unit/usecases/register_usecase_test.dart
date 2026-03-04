import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:Uniguide/features/auth/domain/entities/auth_entity.dart';
import 'package:Uniguide/features/auth/domain/entities/auth_response.dart';
import 'package:Uniguide/features/auth/domain/repositories/auth_repository.dart';
import 'package:Uniguide/features/auth/domain/usecases/register_usecase.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late RegisterUseCase useCase;

  final user = AuthEntity(
    id: '42',
    fullName: 'Ada Lovelace',
    email: 'ada@example.com',
    phone: '+44123456789',
    country: 'UK',
    password: 'Secret123',
  );

  setUpAll(() {
    registerFallbackValue(AuthEntity(
      id: 'fallback',
      fullName: 'Fallback',
      email: 'fallback@example.com',
      phone: '0',
    ));
  });

  setUp(() {
    repository = _MockAuthRepository();
    useCase = RegisterUseCase(repository: repository);
  });

  group('RegisterUseCase', () {
    test('returns repository result on success', () async {
      final expected = AuthResponse.success(user, message: 'Registered successfully');
      when(() => repository.registerUser(user)).thenAnswer((_) async => expected);

      final result = await useCase.execute(user);

      expect(result.success, isTrue);
      expect(result.user?.email, user.email);
      expect(result.message, 'Registered successfully');
    });

    test('forwards the same entity object to repository', () async {
      when(() => repository.registerUser(any()))
          .thenAnswer((_) async => AuthResponse.success(user));

      await useCase.execute(user);

      verify(() => repository.registerUser(user)).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('propagates exceptions thrown by repository', () async {
      when(() => repository.registerUser(user)).thenThrow(Exception('email taken'));

      expect(
        () => useCase.execute(user),
        throwsA(isA<Exception>()),
      );
    });

    test('works with different payloads (edge values)', () async {
      final minimalUser = AuthEntity(
        id: '99',
        fullName: 'Edge Case',
        email: 'edge@example.com',
        phone: '',
      );
      when(() => repository.registerUser(minimalUser))
          .thenAnswer((_) async => AuthResponse.success(minimalUser));

      final result = await useCase.execute(minimalUser);

      expect(result.user?.id, '99');
      expect(result.user?.phone, '');
    });

    test('preserves custom success messages', () async {
      final expected = AuthResponse.success(user, message: 'Welcome!');
      when(() => repository.registerUser(user)).thenAnswer((_) async => expected);

      final result = await useCase.execute(user);

      expect(result.message, 'Welcome!');
    });
  });
}
