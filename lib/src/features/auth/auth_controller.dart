import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import 'auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  bool isLoading = true;
  bool isAuthenticated = false;
  String? errorMessage;

  Future<void> restore() async {
    isLoading = true;
    notifyListeners();
    try {
      isAuthenticated = await _repository.hasSession();
    } catch (error) {
      isAuthenticated = false;
      errorMessage = _message(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.login(email: email, password: password);
      isAuthenticated = true;
      return true;
    } catch (error) {
      isAuthenticated = false;
      errorMessage = _message(error);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();
    try {
      await _repository.logout();
    } finally {
      isAuthenticated = false;
      isLoading = false;
      notifyListeners();
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return 'Nao foi possivel concluir a operacao.';
  }
}
