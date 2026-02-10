import 'package:flutter/material.dart';
import '../../domain/entities/auth_entity.dart';
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

  Future<void> registerUser(AuthEntity user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.registerUser(user);
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginUser(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.loginUser(email, password);
      if (user != null) return true;
      _errorMessage = 'Invalid email or password';
      return false;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
