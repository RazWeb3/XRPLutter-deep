// -------------------------------------------------------
// 目的・役割: XRPL WebSocketイベント購読クライアント。ledger/transactions/account等のイベントを購読する。
// 作成日: 2025/11/15
//
// 更新履歴:
// 2025/11/16 10:27 変更: pingIntervalと受信サイズ上限、サニタイズ済みエラーイベントを追加。
// 理由: 接続安定性とDoS耐性の向上。
// 2025/11/20 変更: 本番向けTLS強制フラグ(enforceTls)を追加し、wsを拒否可能に
// 理由: 誤設定による平文通信を防ぐため
// 2025/11/20 変更: 購読の重複排除（Setキー化）を導入
// 理由: 再接続時の多重送信による負荷・重複イベントを防止
// -------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class XRPLWebSocketClient {
  XRPLWebSocketClient({String? endpoint, bool enforceTls = false})
      : _endpoint = endpoint ?? 'wss://s.altnet.rippletest.net:51233',
        _enforceTls = enforceTls;

  final String _endpoint;
  final bool _enforceTls;
  WebSocket? _socket;
  final StreamController<Map<String, dynamic>> _events = StreamController.broadcast();
  final Set<String> _subscriptionKeys = <String>{};
  final List<Map<String, dynamic>> _subscriptions = [];
  int _reconnectAttempt = 0;

  Stream<Map<String, dynamic>> get events => _events.stream;

  Future<void> connect() async {
    if (_socket != null) return;
    final uri = Uri.parse(_endpoint);
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      throw ArgumentError('XRPL WS endpoint must use ws/wss scheme: ' + _endpoint);
    }
    if (_enforceTls && uri.scheme != 'wss') {
      throw ArgumentError('TLS is required for XRPL WS endpoint (wss only): ' + _endpoint);
    }
    _socket = await WebSocket.connect(_endpoint);
    _socket!.pingInterval = const Duration(seconds: 30);
    const maxLen = 256 * 1024;
    _socket!.listen((data) {
      try {
        final str = data as String;
        if (str.length > maxLen) return;
        final json = jsonDecode(str) as Map<String, dynamic>;
        _events.add(json);
      } catch (_) {
        _events.add({'type': 'error', 'message': 'invalid_json'});
      }
    }, onDone: () {
      _socket = null;
      _scheduleReconnect();
    }, onError: (e) {
      _socket = null;
      _events.add({'type': 'error', 'message': 'ws_error'});
      _scheduleReconnect();
    });
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    _reconnectAttempt = 0;
  }

  Future<void> subscribe(Map<String, dynamic> request) async {
    if (_socket == null) {
      await connect();
    }
    final key = jsonEncode(request);
    if (_subscriptionKeys.add(key)) {
      _subscriptions.add(request);
      _socket!.add(key);
    }
  }

  Future<void> subscribeTransactions({List<String>? accounts}) {
    return subscribe({
      'command': 'subscribe',
      'streams': ['transactions'],
      if (accounts != null && accounts.isNotEmpty) 'accounts': accounts,
    });
  }

  Future<void> subscribeLedger() {
    return subscribe({
      'command': 'subscribe',
      'streams': ['ledger'],
    });
  }

  void _scheduleReconnect() {
    final baseMs = 500 * (1 << (_reconnectAttempt.clamp(0, 5)));
    final jitterMs = ((baseMs * 0.2) * ((DateTime.now().microsecondsSinceEpoch % 1000) / 1000)).round();
    final wait = Duration(milliseconds: baseMs + jitterMs);
    Timer(wait, () async {
      try {
        await connect();
        for (final req in _subscriptions) {
          try {
            _socket?.add(jsonEncode(req));
          } catch (_) {}
        }
        _reconnectAttempt = 0;
      } catch (_) {
        _reconnectAttempt++;
        _scheduleReconnect();
      }
    });
  }
}