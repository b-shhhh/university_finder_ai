import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:Uniguide/features/auth/domain/entities/auth_entity.dart';
import 'package:Uniguide/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:Uniguide/features/auth/presentation/view_model/auth_view_model.dart';

// 1️⃣ Create a Mock class
class MockAuthRepository extends Mock implements AuthRepositoryImpl {}

void main() {
  late AuthViewModel viewModel;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    viewModel = AuthViewModel(repository: mockRepository);
  });

  final testUser = AuthEntity(
    firstName: 'John',
    lastName: 'Doe',
    email: 'test@example.com',
    password: '123456',
    phone: '1234567890',
    education: 'BSc',
  );

  test('Initial state', () {
    expect(viewModel.isLoading, false);
    expect(viewModel.errorMessage, null);
  });

  test('registerUser success', () async {
    when(() => mockRepository.registerUser(testUser))
        .thenAnswer((_) async {});

    final future = viewModel.registerUser(testUser);

    expect(viewModel.isLoading, true);

    await future;

    expect(viewModel.isLoading, false);
    expect(viewModel.errorMessage, null);
    verify(() => mockRepository.registerUser(testUser)).called(1);
  });

  test('registerUser failure', () async {
    when(() => mockRepository.registerUser(testUser))
        .thenThrow(Exception('Server error'));

    await viewModel.registerUser(testUser);

    expect(viewModel.isLoading, false);
    expect(viewModel.errorMessage, contains('Registration failed'));
    verify(() => mockRepository.registerUser(testUser)).called(1);
  });

  test('loginUser success', () async {
    when(() => mockRepository.loginUser('test@example.com', '123456'))
        .thenAnswer((_) async => testUser);

    final result = await viewModel.loginUser('test@example.com', '123456');

    expect(result, true);
    expect(viewModel.isLoading, false);
    expect(viewModel.errorMessage, null);
    verify(() => mockRepository.loginUser('test@example.com', '123456')).called(1);
  });

  test('loginUser failure (invalid credentials)', () async {
    when(() => mockRepository.loginUser('wrong@example.com', '123'))
        .thenAnswer((_) async => null);

    final result = await viewModel.loginUser('wrong@example.com', '123');

    expect(result, false);
    expect(viewModel.isLoading, false);
    expect(viewModel.errorMessage, 'Invalid email or password');
    verify(() => mockRepository.loginUser('wrong@example.com', '123')).called(1);
  });

  test('loginUser throws exception', () async {
    when(() => mockRepository.loginUser('test@example.com', '123456'))
        .thenThrow(Exception('Server error'));

    final result = await viewModel.loginUser('test@example.com', '123456');

    expect(result, false);
    expect(viewModel.isLoading, false);
    expect(viewModel.errorMessage, contains('Login failed'));
    verify(() => mockRepository.loginUser('test@example.com', '123456')).called(1);
  });
}
