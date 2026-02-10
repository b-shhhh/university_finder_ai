import 'package:flutter_test/flutter_test.dart';
import 'package:Uniguide/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:Uniguide/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:Uniguide/features/auth/domain/entities/auth_entity.dart';

class MockAuthRepository extends Mock implements AuthRepositoryImpl {}

void main() {
  late AuthViewModel viewModel;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    viewModel = AuthViewModel(repository: mockRepository);
  });

  test('Initial state', () {
    expect(viewModel.isLoading, false);
    expect(viewModel.errorMessage, null);
  });
}
