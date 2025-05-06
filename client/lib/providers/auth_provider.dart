import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  final AuthService _authService = AuthService();

  User? get user => _user;
  String? get token => _token;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      _user = user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final user = await _authService.login(email: email, password: password);
      _user = user;
       // Assuming User model has a token field
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void clear() {
    _user = null;
    _token = null;
    notifyListeners();
  }
}
