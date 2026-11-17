import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/app_config.dart';
import 'auth_service.dart';
import 'session_service.dart';

/// The app's one live connection to the server. It joins the signed-in
/// user's own room (`user_<id>`), so it must never outlive that user: when
/// a different user is signed in, the next [initSocket] / [on] replaces the
/// connection, or the new user would keep getting the previous one's
/// notifications and comment events.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  bool _isInitializing = false;
  Completer<void>? _initCompleter;

  /// Whose room [socket] joined.
  String? _userId;

  /// Every listener screens have registered, by event — re-attached whenever
  /// the connection is replaced, so a switch of user doesn't drop them.
  final Map<String, List<Function(dynamic)>> _handlers = {};

  /// Connected (or connecting / auto-reconnecting), and for the user signed
  /// in now.
  bool get _isCurrent {
    final s = socket;
    if (s == null || !(s.connected || s.active)) return false;
    final signedIn = SessionService().currentUser?.id;
    return signedIn == null || signedIn == _userId;
  }

  Future<void> initSocket() async {
    if (_isCurrent) return;
    if (_isInitializing && _initCompleter != null) {
      return _initCompleter!.future;
    }

    _isInitializing = true;
    _initCompleter = Completer<void>();
    try {
      final user = await AuthService().getMe();
      if (user == null) {
        _isInitializing = false;
        if (!_initCompleter!.isCompleted) _initCompleter!.complete();
        return;
      }

      // Drop any earlier connection — it may belong to another user.
      _closeSocket();

      final s = IO.io(
        AppConfig.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableForceNew()
            .build(),
      );
      socket = s;
      _userId = user.id;
      _handlers.forEach((event, callbacks) {
        for (final callback in callbacks) {
          s.on(event, callback);
        }
      });

      s.connect();

      s.onConnect((_) {
        s.emit('join', 'user_${user.id}');
      });

      s.onDisconnect((_) => print('Socket disconnected'));

      if (!_initCompleter!.isCompleted) _initCompleter!.complete();
    } catch (e) {
      if (!_initCompleter!.isCompleted) _initCompleter!.completeError(e);
    } finally {
      _isInitializing = false;
    }
  }

  /// Sign-out: close the connection and forget every listener.
  void disconnect() {
    _closeSocket();
    _handlers.clear();
    _isInitializing = false;
    _initCompleter = null;
  }

  void _closeSocket() {
    socket?.dispose(); // disconnects, closes the manager, drops listeners
    socket = null; // Clear socket instance
    _userId = null;
  }

  void on(String event, Function(dynamic) callback) {
    _handlers.putIfAbsent(event, () => []).add(callback);
    if (_isInitializing) return; // attached once the socket is created
    if (_isCurrent) {
      socket?.on(event, callback);
    } else {
      // Not connected yet, or connected as someone else: (re)connect — that
      // attaches every registered listener, this one included.
      initSocket();
    }
  }

  void off(String event) {
    _handlers.remove(event);
    socket?.off(event);
  }
}
