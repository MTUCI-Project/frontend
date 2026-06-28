import '../Api/apiService.dart';

abstract class AuthMain {
  Future<void> signIn(String username, String password);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class BackendAuthMain implements AuthMain {
  @override
  Future<void> signIn(String username, String password) async {
    try {
      await ApiService.instance.login(username, password);
    } catch (error) {
      throw AuthException(error.toString());
    }
  }
}
