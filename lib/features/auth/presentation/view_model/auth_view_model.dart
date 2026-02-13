import 'package:flutter/material.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/entities/auth_response.dart';
import '../../data/repositories/auth_repository_impl.dart';

class AuthViewModel extends ChangeNotifier {
  late final AuthRepositoryImpl _repository;

  // 1️⃣ Add a constructor to inject a repository (optional)
  AuthViewModel({AuthRepositoryImpl? repository}) {
    _repository = repository ?? AuthRepositoryImpl();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  AuthEntity? _user;
  AuthEntity? get user => _user;

  Future<AuthResponse> registerUser(AuthEntity user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.registerUser(user);
      _user = res.user;
      return res;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      return AuthResponse.failure(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthResponse> loginUser(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.loginUser(email, password);
      _user = res.user;
      return res;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      return AuthResponse.failure(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
