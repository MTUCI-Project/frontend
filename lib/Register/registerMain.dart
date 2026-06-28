import '../Api/apiService.dart';

abstract class RegisterMain {
  Future<void> register(String username, String password);
}

class RegisterException implements Exception {
  final String message;
  RegisterException(this.message);

  @override
  String toString() => message;
}

class BackendRegisterMain implements RegisterMain {
  @override
  Future<void> register(String username, String password) async {
    try {
      await ApiService.instance.register(username, password);
    } catch (error) {
      throw RegisterException(error.toString());
    }
  }
}
