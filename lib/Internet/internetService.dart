import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class InternetService {
  static final InternetService _instance = InternetService._internal();
  final Connectivity _connectivity = Connectivity();
  late StreamController<bool> _controller;
  Timer? _periodicTimer;

  InternetService._internal() {
    _controller = StreamController<bool>.broadcast(onCancel: () {
      print('[InternetService] No more listeners, stopping periodic check');
      _stopPeriodicCheck();
    }, onListen: () {
      print('[InternetService] Listener added, starting periodic check');
      _startPeriodicCheck();
    });

    // Слушаем изменения подключения
    _connectivity.onConnectivityChanged.listen((results) {
      print('[InternetService] Connectivity changed: $results');
      _handleConnectivityChange(results);
    });
  }

  factory InternetService() {
    return _instance;
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isConnected = results.isNotEmpty && results.first != ConnectivityResult.none;
    if (!_controller.isClosed) {
      _controller.add(isConnected);
    }
  }

  void _startPeriodicCheck() {
    if (_periodicTimer != null) return;
    print('[InternetService] Starting periodic connection check');
    
    _periodicTimer = Timer.periodic(Duration(seconds: 3), (_) async {
      if (!_controller.isClosed) {
        final connected = await hasConnection();
        if (!_controller.isClosed) {
          _controller.add(connected);
        }
      }
    });
  }

  void _stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Поток изменений статуса подключения
  Stream<bool> get connectionStatusStream {
    return _controller.stream;
  }

  /// Проверка текущего подключения
  Future<bool> hasConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final isConnected = results.isNotEmpty && results.first != ConnectivityResult.none;
      print('[InternetService] hasConnection: $isConnected (results: $results)');
      return isConnected;
    } catch (e) {
      print('[InternetService] Error checking connection: $e');
      return false;
    }
  }

  void dispose() {
    _stopPeriodicCheck();
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
