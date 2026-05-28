import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/app_config.dart';
import 'auth_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  bool _isInitializing = false;
  Completer<void>? _initCompleter;

  Future<void> initSocket() async {
    if (socket != null && socket!.connected) return;
    if (_isInitializing && _initCompleter != null) return _initCompleter!.future;

    _isInitializing = true;
    _initCompleter = Completer<void>();
    try {
      final user = await AuthService().getMe();
      if (user == null) {
        _isInitializing = false;
        if (!_initCompleter!.isCompleted) _initCompleter!.complete();
        return;
      }

      // Clean up any existing socket connection
      if (socket != null) {
        socket?.disconnect();
        socket?.destroy();
      }

      socket = IO.io(
        AppConfig.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      socket?.connect();

      socket?.onConnect((_) {
        print('Socket connected for user_${user.id}');
        socket?.emit('join', 'user_${user.id}');
      });

      socket?.onDisconnect((_) => print('Socket disconnected'));

      if (!_initCompleter!.isCompleted) _initCompleter!.complete();
    } catch (e) {
      print('Socket init error: $e');
      if (!_initCompleter!.isCompleted) _initCompleter!.completeError(e);
    } finally {
      _isInitializing = false;
    }
  }

  void disconnect() {
    socket?.disconnect();
    socket?.destroy();
    socket = null; // Clear socket instance
    _isInitializing = false;
    _initCompleter = null;
  }

  void on(String event, Function(dynamic) callback) {
    if (socket != null) {
      socket?.on(event, callback);
    } else {
      // If socket is not initialized, try to init and then listen
      print('Socket not ready for $event. Initializing...');
      initSocket().then((_) {
        // Double check socket is not null after init
        if (socket != null) {
          socket?.on(event, callback);
        }
      });
    }
  }

  void off(String event) {
    socket?.off(event);
  }
}
