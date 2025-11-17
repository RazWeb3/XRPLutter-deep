// -------------------------------------------------------
// 目的・役割: XRPLutter WalletConnectorの進捗イベント（created/opened/signed/submitted/canceled 他）を可視化するデモUI。
// 作成日: 2025/11/09
//
// 更新履歴:
// 2025/11/09 14:27 追記: DeepLinkのQR表示とコピー対応、イベント時刻表示を追加。
// 理由: UI/UX確認の利便性を高めるため。
// 2025/11/09 15:12 追記: イベントログのフィルタ/クリア、QRサイズ調整、Copy成功トースト強化、時刻フォーマット（intl）を追加。
// 理由: デモUIの操作性と視認性を向上するため。
// 2025/11/09 15:55 追記: 設定フラグの切り替えUI（webSubmitByExtension/verifyAddressBeforeSign）とConnector再初期化処理を追加。
// 理由: Web拡張submit方式の切替や署名前のアドレス整合検証のON/OFFを実機検証可能にするため。
// 2025/11/09 16:48 追記: 拡張検出ステータス（Crossmark/GemWallet）表示を追加。
// 理由: 実機ブラウザで拡張が認識されているかを事前に確認しやすくし、検証手順を明確化するため。
// 2025/11/09 17:24 追記: 拡張からの現在アドレス/ネットワークの読取ボタンを追加（Webのみ）。
// 理由: 実機検証でアドレス整合チェックやネットワーク確認を即時に行えるようにするため。
// 2025/11/09 17:32 追記: セッションアドレスの表示を追加。接続時にWalletConnectorから取得したアドレスを表示。
// 理由: verifyAddressBeforeSignの検証に役立て、接続状態の把握を容易にするため。
// 2025/11/09 18:22 変更: レスポンシブ2カラムレイアウトへ刷新。右側にスクロール可能なログパネルを固定配置し、全体スクロールも可能にして操作性を改善。
// 理由: 画面縮小しないと下部ログが確認しづらい課題があったため、広い画面では2カラムで視認性を向上、小さい画面でも縦スクロールで確認可能とするため。
// 2025/11/10 09:14 追記: 右パネルのログ一括コピー機能（Copy logs）を追加。行単位の詳細（state/payloadId/txHash/deepLink/message/time）を文字列化してクリップボードへ保存。
// 理由: ログ共有の利便性を高めるため、右パネルからそのままコピーできるようにするため。
// 2025/11/10 11:12 変更: サンプル署名トランザクションを「自分宛て1 drop送金」に変更し、可能ならAccount/Destinationにセッションアドレスを使用。
// 理由: ダミーDestinationでは拡張が承認できずタイムアウトしやすいため、最小限で成功しやすいトランザクションに調整。
// 2025/11/10 10:58 追記: タイムアウト調整UI（Signing timeout）を追加し、WalletConnectorConfig.signingTimeout を画面から動的変更可能に。
// 理由: 実機検証で承認に要する時間を柔軟に調整し、UXとテストの再現性を高めるため。
// 2025/11/10 14:22 追加: WalletConnect v2 接続ボタン（Connect WalletConnect）を追加。WCペアリングURI（wc:）のDeepLink/QR表示もイベント経由で可視化。
// 理由: セッション・ペアリング・署名イベントのスケルトンをUIから確認できるようにするため。
// 2025/11/10 19:24 追記: WalletConnect Proxy Base URL 入力欄を追加し、SDKへ渡す設定をUIから指定可能に。
// 理由: マネージド/自前プロキシのベースURLをデモで切り替え検証するため。SDK側はUri.resolveで末尾スラッシュ有無を吸収。
// 2025/11/13 12:45 変更: QR表示セクションをフィルタ群より上へ移動し、作成直後に視認できるように調整。
// 理由: 作成イベント後にQRが画面外にあると見逃しやすいため、即時確認できる配置に改善。
// 2025/11/13 12:45 変更: connectフローで_deepLink/_qrUrlのリセットを廃止し、イベントで設定されたリンクを保持。
// 理由: 接続直後のリセットによりQRが消えるケースがあるため、イベント駆動の表示を維持する。
// 2025/11/13 14:20 追加: ステータス表示パネル（opened/signed/rejected/txHash）を追加し、診断性を向上。
// 理由: 進捗ログだけでなく現況を明示してユーザー確認を容易にするため。
// 2025/11/17 12:10 追加: RWAデモ（MPT発行＋EscrowをBatchで原子的署名）ボタンを追加。
// 理由: ハッカソン評価に向けDevnetで検証しやすい最新機能の体験を提供するため。
// 2025/11/17 12:25 追加: Escrow事前検証（Preflight）ボタンと結果表示を追加。
// 理由: 送信前に失敗条件をUIで提示し、デモの完成度を高めるため。
// 2025/11/17 12:40 追加: IOUネットワーク事前検証入力欄と結果表示を追加。
// 理由: account_info/account_linesから実際の状態を読取り、送信前に検証できるようにするため。
// 2025/11/17 12:45 追加: MPTメタデータ入力フォームと圧縮プレビューを追加。
// 理由: XLS-89準拠メタデータの入力→圧縮→バイト数確認までUIで行えるようにするため。
// 2025/11/17 13:10 追加: モード比較（Batch）デモ処理を実装。
// 理由: 未定義ハンドラでビルドエラーが発生していたための解消と、各モード挙動の体験補完。
// -------------------------------------------------------
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:xrplutter_sdk/xrplutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Web拡張検出のため（デモ用に直接参照）
// デモはWeb環境での実行を前提とするため、dart:html/js_utilの使用を許容
import 'dart:js_util' as js_util;
import 'dart:html' as html;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XRPLutter WalletConnector Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WalletConnectorDemo(),
    );
  }
}

class WalletConnectorDemo extends StatefulWidget {
  const WalletConnectorDemo({super.key});

  @override
  State<WalletConnectorDemo> createState() => _WalletConnectorDemoState();
}

class _WalletConnectorDemoState extends State<WalletConnectorDemo> {
  WalletConnector _connector = WalletConnector();
  WalletProvider? _provider;
  final List<SignProgressEvent> _events = [];
  final List<SignProgressEvent> _pendingUiEvents = [];
  String? _deepLink;
  String? _qrUrl;
  String? _resultHash;
  String? _sessionAddress;
  bool _statusOpened = false;
  bool _statusSigned = false;
  bool _statusRejected = false;
  String? _lastError;
  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd HH:mm:ss');
  Timer? _uiBatchTimer;
  final Map<SignProgressState, bool> _filterEnabled = {
    SignProgressState.created: true,
    SignProgressState.opened: true,
    SignProgressState.signed: true,
    SignProgressState.submitted: true,
    SignProgressState.canceled: true,
    SignProgressState.rejected: true,
    SignProgressState.timeout: true,
    SignProgressState.error: true,
  };
  double _qrSize = 180.0;
  bool _webSubmitByExtension = true;
  bool _verifyAddressBeforeSign = false;
  int _signingTimeoutSeconds = 45;
  int _batchMode = BatchService.tfAllOrNothing;
  // Web拡張からの情報読取（デモ用）
  String? _addrCrossmark;
  String? _addrGemWallet;
  String? _network;
  final TextEditingController _wcProxyController = TextEditingController();
  final TextEditingController _xamanProxyController = TextEditingController();
  final TextEditingController _jwtController = TextEditingController(text: '');
  static const String _envWcProxy = String.fromEnvironment('WC_PROXY_BASE_URL');
  static const String _envXamanProxy = String.fromEnvironment(
    'XAMAN_PROXY_BASE_URL',
  );
  static const String _envJwt = String.fromEnvironment('JWT_BEARER_TOKEN');
  StreamSubscription<SignProgressEvent>? _progressSub;
  final XRPLClient _xrplClient = XRPLClient(
    timeout: const Duration(seconds: 12),
    maxRetries: 3,
    retryBaseDelayMs: 300,
  );
  // サービス群（MPT/Escrow/Batch）
  late final TokenService _tokenService = TokenService(client: _xrplClient);
  late final EscrowService _escrowService = EscrowService(client: _xrplClient);
  late final BatchService _batchService = BatchService(client: _xrplClient);
  late final PaymentService _paymentService = PaymentService(client: _xrplClient);
  late final EscrowPreflightClient _preflightClient = EscrowPreflightClient(client: _xrplClient);
  // IOUネットワーク事前検証入力
  final TextEditingController _issuerCtrl = TextEditingController(text: 'rISSUER_EXAMPLE');
  final TextEditingController _currencyCtrl = TextEditingController(text: 'USD');
  final TextEditingController _amountCtrl = TextEditingController(text: '10');
  final TextEditingController _destCtrl = TextEditingController(text: '');
  // MPTメタデータフォーム
  final TextEditingController _mptTickerCtrl = TextEditingController(text: 'USTBT');
  final TextEditingController _mptNameCtrl = TextEditingController(text: 'US Treasury Bill');
  final TextEditingController _mptClassCtrl = TextEditingController(text: 'rwa');
  final TextEditingController _mptIssuerNameCtrl = TextEditingController(text: 'US Treasury');
  final TextEditingController _mptDescCtrl = TextEditingController(text: 'Short term debt');
  final TextEditingController _mptIconCtrl = TextEditingController(text: 'https://example.com/icon.png');
  final TextEditingController _mptMaxAmountCtrl = TextEditingController(text: '1000000');
  final TextEditingController _mptTransferFeeCtrl = TextEditingController(text: '100');
  final TextEditingController _mptFlagsCtrl = TextEditingController(text: '0');
  bool _mptFlagCanTransfer = true;
  bool _mptFlagRequireAuth = false;
  bool _mptFlagCanLock = false;
  final TextEditingController _batchPreviewPatternCtrl = TextEditingController(text: 'F,T,T');

  @override
  void initState() {
    super.initState();
    if (_envWcProxy.isNotEmpty) {
      _wcProxyController.text = _envWcProxy;
    }
    if (_envXamanProxy.isNotEmpty) {
      _xamanProxyController.text = _envXamanProxy;
    }
    if (_envJwt.isNotEmpty) {
      _jwtController.text = _envJwt;
    }
    _progressSub = _connector.progressStream
        .distinct(
          (a, b) =>
              a.state == b.state &&
              (a.payloadId ?? '') == (b.payloadId ?? '') &&
              (a.txHash ?? '') == (b.txHash ?? ''),
        )
        .listen((e) {
          _pendingUiEvents.add(e);
          _uiBatchTimer ??= Timer(const Duration(milliseconds: 50), () {
            final batch = List<SignProgressEvent>.from(_pendingUiEvents);
            _pendingUiEvents.clear();
            _uiBatchTimer = null;
            setState(() {
              for (final ev in batch) {
                _events.add(ev);
                if ((ev.deepLink ?? '').isNotEmpty) _deepLink = ev.deepLink;
                if ((ev.qrUrl ?? '').isNotEmpty) _qrUrl = ev.qrUrl;
                if ((ev.deepLink ?? '').isEmpty &&
                    (ev.payloadId ?? '').isNotEmpty) {
                  _deepLink = 'https://xumm.app/sign/${ev.payloadId}';
                  _qrUrl = 'https://xumm.app/sign/${ev.payloadId}_q.png';
                }
                if (ev.txHash != null) _resultHash = ev.txHash;
                if (ev.state == SignProgressState.opened) {
                  _statusOpened = true;
                } else if (ev.state == SignProgressState.signed) {
                  _statusSigned = true;
                } else if (ev.state == SignProgressState.rejected) {
                  _statusRejected = true;
                } else if (ev.state == SignProgressState.error) {
                  _lastError = ev.message;
                }
              }
            });
          });
        });
  }

  Future<void> _readExtensionInfo() async {
    if (!kIsWeb) return;
    String? cmAddr;
    String? gwAddr;
    String? network;
    try {
      final cm = js_util.getProperty(html.window, 'crossmark');
      if (cm != null) {
        if (js_util.hasProperty(cm, 'getAddress')) {
          final p = js_util.callMethod(cm, 'getAddress', []);
          cmAddr = await js_util.promiseToFuture(p);
        } else if (js_util.hasProperty(cm, 'address')) {
          cmAddr = js_util.getProperty(cm, 'address');
        } else if (js_util.hasProperty(cm, 'request')) {
          final p = js_util.callMethod(cm, 'request', [
            {'method': 'getAddress'},
          ]);
          cmAddr = await js_util.promiseToFuture(p);
        }
      }
    } catch (_) {}
    try {
      dynamic gw = js_util.getProperty(html.window, 'gemWallet');
      gw ??= js_util.getProperty(html.window, 'gemwallet');
      gw ??= js_util.getProperty(html.window, 'gem_wallet');
      if (gw != null) {
        if (js_util.hasProperty(gw, 'getAddress')) {
          final p = js_util.callMethod(gw, 'getAddress', []);
          gwAddr = await js_util.promiseToFuture(p);
        } else if (js_util.hasProperty(gw, 'address')) {
          gwAddr = js_util.getProperty(gw, 'address');
        } else if (js_util.hasProperty(gw, 'request')) {
          final p = js_util.callMethod(gw, 'request', [
            {'method': 'getAddress'},
          ]);
          gwAddr = await js_util.promiseToFuture(p);
        }
      }
    } catch (_) {}
    try {
      final cm = js_util.getProperty(html.window, 'crossmark');
      dynamic gw = js_util.getProperty(html.window, 'gemWallet');
      gw ??= js_util.getProperty(html.window, 'gemwallet');
      gw ??= js_util.getProperty(html.window, 'gem_wallet');
      for (final obj in [cm, gw]) {
        if (obj == null) continue;
        try {
          if (js_util.hasProperty(obj, 'getNetwork')) {
            final p = js_util.callMethod(obj, 'getNetwork', []);
            final v = await js_util.promiseToFuture(p);
            if (v != null) {
              network = v.toString();
              break;
            }
          } else if (js_util.hasProperty(obj, 'network')) {
            final v = js_util.getProperty(obj, 'network');
            if (v != null) {
              network = v.toString();
              break;
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    setState(() {
      _addrCrossmark = cmAddr;
      _addrGemWallet = gwAddr;
      _network = network;
    });
  }

  Future<void> _connect(WalletProvider provider) async {
    // 設定フラグを反映した新しいWalletConnectorを生成
    // WalletConnect Proxy Base URL（任意）を設定（空なら未設定）
    Uri? wcBase;
    Uri? xamanBase;
    final wcText = _wcProxyController.text.trim();
    if (wcText.isNotEmpty) {
      try {
        final u = Uri.parse(wcText);
        final s = u.scheme.toLowerCase();
        if (s == 'http' || s == 'https') {
          wcBase = u;
        } else {
          _lastError = 'Invalid WC proxy URL scheme: ${u.scheme}';
        }
      } catch (_) {
        _lastError = 'Invalid WC proxy URL';
      }
    }
    final xamanText = _xamanProxyController.text.trim();
    if (xamanText.isNotEmpty) {
      try {
        final u = Uri.parse(xamanText);
        final s = u.scheme.toLowerCase();
        if (s == 'http' || s == 'https') {
          xamanBase = u;
        } else {
          _lastError = 'Invalid Xaman proxy URL scheme: ${u.scheme}';
        }
      } catch (_) {
        _lastError = 'Invalid Xaman proxy URL';
      }
    }
    final jwtText = _jwtController.text.trim();
    _connector = WalletConnector(
      config: WalletConnectorConfig(
        webSubmitByExtension: _webSubmitByExtension,
        verifyAddressBeforeSign: _verifyAddressBeforeSign,
        signingTimeout: Duration(seconds: _signingTimeoutSeconds),
        walletConnectProxyBaseUrl: wcBase,
        xamanProxyBaseUrl: xamanBase,
        jwtBearerToken: jwtText.isNotEmpty ? jwtText : null,
      ),
      client: _xrplClient,
    );
    // 進捗イベントの購読を再設定
    await _progressSub?.cancel();
    _progressSub = _connector.progressStream
        .distinct(
          (a, b) =>
              a.state == b.state &&
              (a.payloadId ?? '') == (b.payloadId ?? '') &&
              (a.txHash ?? '') == (b.txHash ?? ''),
        )
        .listen((e) {
          _pendingUiEvents.add(e);
          _uiBatchTimer ??= Timer(const Duration(milliseconds: 50), () {
            final batch = List<SignProgressEvent>.from(_pendingUiEvents);
            _pendingUiEvents.clear();
            _uiBatchTimer = null;
            setState(() {
              for (final ev in batch) {
                _events.add(ev);
                if ((ev.deepLink ?? '').isNotEmpty) _deepLink = ev.deepLink;
                if ((ev.qrUrl ?? '').isNotEmpty) _qrUrl = ev.qrUrl;
                if ((ev.deepLink ?? '').isEmpty &&
                    (ev.payloadId ?? '').isNotEmpty) {
                  _deepLink = 'https://xumm.app/sign/${ev.payloadId}';
                  _qrUrl = 'https://xumm.app/sign/${ev.payloadId}_q.png';
                }
                if (ev.txHash != null) _resultHash = ev.txHash;
                if (ev.state == SignProgressState.opened) {
                  _statusOpened = true;
                } else if (ev.state == SignProgressState.signed) {
                  _statusSigned = true;
                } else if (ev.state == SignProgressState.rejected) {
                  _statusRejected = true;
                } else if (ev.state == SignProgressState.error) {
                  _lastError = ev.message;
                }
              }
            });
          });
        });

    await _connector.connect(provider: provider);
    // 接続直後にセッションアドレスを取得
    try {
      final info = await _connector.getAccountInfo();
      _sessionAddress = info.address;
    } catch (_) {}
    setState(() {
      _provider = provider;
      _events.clear();
      _resultHash = null;
      _statusOpened = false;
      _statusSigned = false;
      _statusRejected = false;
      _lastError = null;
    });
  }

  Future<void> _signSample() async {
    Map<String, dynamic> txJson;
    final isXaman =
        (_provider?.name.toLowerCase() == 'xaman' ||
        _provider?.name.toLowerCase() == 'xumm');
    if (isXaman) {
      txJson = {'TransactionType': 'SignIn'};
    } else {
      final dest = _sessionAddress ?? 'rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpRWL';
      txJson = {
        'TransactionType': 'Payment',
        'Destination': dest,
        'Amount': '1',
      };
    }
    try {
      final res = await _connector.signAndSubmit(txJson: txJson);
      setState(() {
        _resultHash = res['result']?['hash'] as String?;
      });
    } catch (e) {
      setState(() {
        _events.add(
          SignProgressEvent(
            state: SignProgressState.canceled,
            message: 'Error: $e',
          ),
        );
      });
    }
  }

  void _cancel() {
    _connector.cancelSigning();
  }

  void _clearLogs() {
    setState(() {
      _events.clear();
      _resultHash = null;
      _statusOpened = false;
      _statusSigned = false;
      _statusRejected = false;
      _lastError = null;
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _wcProxyController.dispose();
    _xamanProxyController.dispose();
    _jwtController.dispose();
    super.dispose();
  }

  // フィルタ適用後のイベント一覧
  List<SignProgressEvent> _filteredEvents() {
    return _events.where((e) => _filterEnabled[e.state] ?? true).toList();
  }

  // 1行のログ文字列を整形
  String _formatEventLine(SignProgressEvent e) {
    final ts = _dateFmt.format(e.timestamp.toLocal());
    final parts = <String>[
      'state=${e.state.name}',
      if ((e.payloadId ?? '').isNotEmpty) 'payloadId=${e.payloadId}',
      if ((e.txHash ?? '').isNotEmpty) 'txHash=${e.txHash}',
      if ((e.deepLink ?? '').isNotEmpty) 'deepLink=${e.deepLink}',
      if ((e.qrUrl ?? '').isNotEmpty) 'qrUrl=${e.qrUrl}',
      if ((e.message ?? '').isNotEmpty) 'message=${e.message}',
      'time=$ts',
    ];
    return parts.join(' | ');
  }

  // 右パネルのログをクリップボードへコピー
  void _copyLogs() {
    final lines = _filteredEvents().map(_formatEventLine).join('\n');
    Clipboard.setData(ClipboardData(text: lines));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Logs copied (${_filteredEvents().length} lines)'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1600),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // 拡張検出（Webのみ評価）
    bool crossmarkDetected = false;
    bool gemwalletDetected = false;
    if (kIsWeb) {
      try {
        crossmarkDetected =
            js_util.hasProperty(html.window, 'crossmark') &&
            js_util.getProperty(html.window, 'crossmark') != null;
      } catch (_) {}
      try {
        gemwalletDetected =
            (js_util.hasProperty(html.window, 'gemWallet') &&
                js_util.getProperty(html.window, 'gemWallet') != null) ||
            (js_util.hasProperty(html.window, 'gemwallet') &&
                js_util.getProperty(html.window, 'gemwallet') != null) ||
            (js_util.hasProperty(html.window, 'gem_wallet') &&
                js_util.getProperty(html.window, 'gem_wallet') != null);
      } catch (_) {}
    }
    return Scaffold(
      appBar: AppBar(title: const Text('WalletConnector Progress Demo')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 900;
          // 左カラム（検出/読取/設定/操作/QR）
          final leftColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拡張検出ステータス
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Crossmark: ${crossmarkDetected ? 'Detected' : 'Not detected'}',
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'GemWallet: ${gemwalletDetected ? 'Detected' : 'Not detected'}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 拡張からの情報読取（Webのみ）
              if (kIsWeb)
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Crossmark Address: ${_addrCrossmark ?? '-'}',
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'GemWallet Address: ${_addrGemWallet ?? '-'}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Network: ${_network ?? '-'}'),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: _readExtensionInfo,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Read address/network'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // 設定フラグの切替UI
              Card(
                elevation: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('拡張側でsubmitする（webSubmitByExtension）'),
                      subtitle: const Text(
                        'true: 署名後に拡張がXRPLへ送信。false: SDK側でtx_blobをsubmit',
                      ),
                      value: _webSubmitByExtension,
                      onChanged: (v) =>
                          setState(() => _webSubmitByExtension = v),
                    ),
                    SwitchListTile(
                      title: const Text(
                        '署名前にアドレス整合チェック（verifyAddressBeforeSign）',
                      ),
                      subtitle: const Text(
                        'true: 拡張から取得した現在アドレスとセッションアドレスの一致を検証',
                      ),
                      value: _verifyAddressBeforeSign,
                      onChanged: (v) =>
                          setState(() => _verifyAddressBeforeSign = v),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        children: [
                          const Text('Signing timeout (sec)'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Slider(
                              value: _signingTimeoutSeconds.toDouble(),
                              min: 10,
                              max: 120,
                              divisions: 22,
                              label: '${_signingTimeoutSeconds}s',
                              onChanged: (v) => setState(
                                () => _signingTimeoutSeconds = v.round(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${_signingTimeoutSeconds}s',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // IOUネットワーク事前検証
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Escrow Preflight (IOU, network)'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _issuerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Issuer account',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _currencyCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Currency',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _amountCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Required amount',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _destCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Destination account (optional)',
                          helperText: '未入力の場合はセッションアドレスを使用',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _runIouPreflightNetwork,
                          icon: const Icon(Icons.network_check),
                          label: const Text('Run IOU preflight (network)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // MPTメタデータフォーム
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MPT Metadata (XLS-89)'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mptTickerCtrl,
                              decoration: const InputDecoration(
                                labelText: 'ticker',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _mptNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mptClassCtrl,
                              decoration: const InputDecoration(
                                labelText: 'asset_class',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _mptIssuerNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'issuer_name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _mptDescCtrl,
                        decoration: const InputDecoration(
                          labelText: 'desc',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _mptIconCtrl,
                        decoration: const InputDecoration(
                          labelText: 'icon (URL)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _previewCompressedMptMetadata,
                          icon: const Icon(Icons.compress),
                          label: const Text('Preview compressed metadata'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // MPT発行オプション（MaxAmount/TransferFee/Flags）とBatch実行
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MPT Issuance Options'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mptMaxAmountCtrl,
                              decoration: const InputDecoration(
                                labelText: 'MaxAmount',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _mptTransferFeeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'TransferFee (例: 100=0.01%)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('CanTransfer (bit 1)'),
                              value: _mptFlagCanTransfer,
                              onChanged: (v) => setState(() {
                                _mptFlagCanTransfer = v;
                                _updateMptFlagsFromToggles();
                              }),
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('RequireAuth (bit 2)'),
                              value: _mptFlagRequireAuth,
                              onChanged: (v) => setState(() {
                                _mptFlagRequireAuth = v;
                                _updateMptFlagsFromToggles();
                              }),
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('CanLock (bit 4)'),
                              value: _mptFlagCanLock,
                              onChanged: (v) => setState(() {
                                _mptFlagCanLock = v;
                                _updateMptFlagsFromToggles();
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _mptFlagsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Issuance Flags (numeric)',
                          helperText: 'トグル＋直接入力の合算値を送信',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _signIssueMptBatchFromForm,
                          icon: const Icon(Icons.token),
                          label: const Text('Issue MPT + Escrow (Batch)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // MPT発行オプション（MaxAmount/TransferFee）とBatch実行
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MPT Issuance Options'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mptMaxAmountCtrl,
                              decoration: const InputDecoration(
                                labelText: 'MaxAmount',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _mptTransferFeeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'TransferFee (例: 100=0.01%)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _signIssueMptBatchFromForm,
                          icon: const Icon(Icons.token),
                          label: const Text('Issue MPT + Escrow (Batch)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // WalletConnect Proxy Base URL 入力欄
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('WalletConnect Proxy Base URL (optional)'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _wcProxyController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              '例: http://localhost:53211/walletconnect/v1/',
                          helperText:
                              '末尾スラッシュ有無はどちらでも可。SDKが安全に連結します（Uri.resolve）。',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Xaman (XUMM) Proxy Base URL (optional)'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _xamanProxyController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '例: http://localhost:53211/xumm/v1/',
                          helperText: '末尾スラッシュ有無はどちらでも可（Uri.resolve）。',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('JWT Bearer Token (開発用は dev-secret)'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _jwtController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '例: dev-secret',
                          helperText: 'Authorization: Bearer <token> として送信します。',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _connect(WalletProvider.crossmark),
                    icon: const Icon(Icons.extension),
                    label: const Text('Connect Crossmark'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _connect(WalletProvider.gemwallet),
                    icon: const Icon(Icons.diamond),
                    label: const Text('Connect GemWallet'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _connect(WalletProvider.walletconnect),
                    icon: const Icon(Icons.link),
                    label: const Text('Connect WalletConnect'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _connect(WalletProvider.xaman),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Connect Xaman (XUMM)'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _signSample,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry signing'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _cancel,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Signing'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _signSample,
                    icon: const Icon(Icons.send),
                    label: const Text('Sign sample tx'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _clearLogs,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear logs'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _signRwaBatchDemo,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Sign RWA demo (Batch)'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _preflightEscrowDemo,
                    icon: const Icon(Icons.fact_check),
                    label: const Text('Preflight Escrow (simulate)'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _signTwoPaymentsBatchDemo,
                    icon: const Icon(Icons.bolt),
                    label: const Text('Sign 2 Payments (Batch)'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _signBatchFailureDemo,
                    icon: const Icon(Icons.warning_amber),
                    label: const Text('Sign Batch Failure Demo'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _signModeComparisonBatchDemo,
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('Mode Comparison (Batch)'),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _batchPreviewPatternCtrl,
                      decoration: const InputDecoration(
                        hintText: 'F,T,T',
                        labelText: 'Success pattern',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _previewModeApplied,
                    icon: const Icon(Icons.visibility),
                    label: const Text('Preview Applied (Mode)'),
                  ),
                  DropdownButton<int>(
                    value: _batchMode,
                    items: const [
                      DropdownMenuItem(
                        value: BatchService.tfAllOrNothing,
                        child: Text('Batch: ALLORNOTHING'),
                      ),
                      DropdownMenuItem(
                        value: BatchService.tfOnlyOne,
                        child: Text('Batch: ONLYONE'),
                      ),
                      DropdownMenuItem(
                        value: BatchService.tfUntilFailure,
                        child: Text('Batch: UNTILFAILURE'),
                      ),
                      DropdownMenuItem(
                        value: BatchService.tfIndependent,
                        child: Text('Batch: INDEPENDENT'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _batchMode = v ?? _batchMode),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Connected: ${_provider?.name ?? 'none'}'),
              const SizedBox(height: 4),
              Text('Session address: ${_sessionAddress ?? '-'}'),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: Text('opened: $_statusOpened')),
                          Expanded(child: Text('signed: $_statusSigned')),
                          Expanded(child: Text('rejected: $_statusRejected')),
                        ],
                      ),
                      if (_resultHash != null) Text('txHash: $_resultHash'),
                      if (_lastError != null)
                        Text(
                          'error: $_lastError',
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
              if (_deepLink != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('DeepLink'),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Copy',
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _deepLink!),
                              );
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text('DeepLink copied'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(milliseconds: 1200),
                                  ),
                                );
                            },
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              try {
                                final u = Uri.parse(_deepLink!);
                                final s = u.scheme.toLowerCase();
                                final host = u.host.toLowerCase();
                                if (s == 'https' && host == 'xumm.app') {
                                  html.window.open(_deepLink!, '_blank');
                                } else if (s == 'http' || s == 'https') {
                                  html.window.open(_deepLink!, '_blank');
                                } else {
                                  ScaffoldMessenger.of(context)
                                    ..clearSnackBars()
                                    ..showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Unsafe deep link scheme blocked',
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(milliseconds: 1600),
                                      ),
                                    );
                                }
                              } catch (_) {}
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open Xaman link'),
                          ),
                        ],
                      ),
                      SelectableText(_deepLink!),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('QR size'),
                          Expanded(
                            child: Slider(
                              value: _qrSize,
                              min: 120,
                              max: 320,
                              divisions: 10,
                              label: '${_qrSize.toInt()}px',
                              onChanged: (v) => setState(() => _qrSize = v),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: _qrSize,
                        width: _qrSize,
                        child: RepaintBoundary(
                          child: QrImageView(
                            data: _deepLink!,
                            version: QrVersions.auto,
                            gapless: true,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_deepLink == null && _qrUrl != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orangeAccent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('QR Image URL (from proxy)'),
                      const SizedBox(height: 6),
                      SelectableText(_qrUrl!),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: _qrSize,
                        width: _qrSize,
                        child: (() {
                          try {
                            final u = Uri.parse(_qrUrl!);
                            final s = u.scheme.toLowerCase();
                            if (s == 'http' || s == 'https') {
                              return Image.network(
                                _qrUrl!,
                                cacheWidth: _qrSize.toInt(),
                                cacheHeight: _qrSize.toInt(),
                                filterQuality: FilterQuality.low,
                                errorBuilder: (c, e, s) => const Center(
                                  child: Text('Failed to load image'),
                                ),
                              );
                            }
                          } catch (_) {}
                          return const Center(
                            child: Text('Blocked non-HTTP(S) image URL'),
                          );
                        })(),
                      ),
                    ],
                  ),
                ),
              // フィルタチップ群
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: SignProgressState.values.map((s) {
                  return FilterChip(
                    label: Text(s.name),
                    selected: _filterEnabled[s] ?? true,
                    onSelected: (v) => setState(() => _filterEnabled[s] = v),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          );

          // 右カラム（ログパネル）
          final rightColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Event logs'),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _copyLogs,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy logs'),
                  ),
                ],
              ),
              _buildLogPanel(context, isWide),
              if (_resultHash != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Result hash: $_resultHash'),
                ),
            ],
          );

          if (isWide) {
            // 横並び（2カラム）＋各カラム個別スクロール
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(child: leftColumn),
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: rightColumn),
                ],
              ),
            );
          }
          // 縦並び（1カラム）＋全体スクロール
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [leftColumn, const SizedBox(height: 12), rightColumn],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconForState(SignProgressState state) {
    switch (state) {
      case SignProgressState.created:
        return Icons.create;
      case SignProgressState.opened:
        return Icons.open_in_new;
      case SignProgressState.signed:
        return Icons.check_circle;
      case SignProgressState.submitted:
        return Icons.outbox;
      case SignProgressState.canceled:
        return Icons.cancel_outlined;
      case SignProgressState.rejected:
        return Icons.block;
      case SignProgressState.timeout:
        return Icons.timer_off;
      case SignProgressState.error:
        return Icons.error_outline;
    }
  }

  // ログパネル（右カラム用／1カラム時は下部）
  Widget _buildLogPanel(BuildContext context, bool isWide) {
    final filtered = _events
        .where((e) => _filterEnabled[e.state] ?? true)
        .toList();
    final double logHeight = isWide
        ? MediaQuery.of(context).size.height * 0.6
        : 380.0;
    return Container(
      height: logHeight,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: filtered.length,
        itemExtent: 56,
        itemBuilder: (context, index) {
          final e = filtered[index];
          final ts = _dateFmt.format(e.timestamp.toLocal());
          return ListTile(
            leading: Icon(_iconForState(e.state)),
            title: Text(e.state.name),
            subtitle: Text(
              [e.message, ts].where((x) => (x ?? '').isNotEmpty).join(' | '),
            ),
            trailing: e.txHash != null ? Text(e.txHash!) : null,
          );
        },
      ),
    );
  }

  // Ripple Epoch（2000-01-01）からの秒数を返す
  int _toRippleEpochSeconds(DateTime dt) {
    final unix = dt.toUtc().millisecondsSinceEpoch ~/ 1000;
    return unix - 946684800;
  }

  Future<void> _signRwaBatchDemo() async {
    final acct = _sessionAddress ?? 'rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpRWL';
    // 1) MPT発行（最小フィールド＋圧縮メタデータ）
    final issuanceTx = _tokenService.buildMPTIssuanceCreateTxJson(
      accountAddress: acct,
      assetScale: 2,
      maxAmount: '1000000',
      transferFee: 100, // 0.01%
      metadataJson: _tokenService.compactMetadata({
        'ticker': 'USTBT',
        'name': 'US Treasury Bill',
        'asset_class': 'rwa',
        'issuer_name': 'US Treasury',
      }),
    );

    // 2) Escrow（XRP 10 drops、10分後にFinish可能）
    final finishAfter = _toRippleEpochSeconds(DateTime.now().toUtc().add(const Duration(minutes: 10)));
    final escrowCreateTx = _escrowService.buildEscrowCreateTxJson(
      accountAddress: acct,
      destinationAddress: acct,
      amount: '10',
      finishAfter: finishAfter,
    );

    // 3) Batchでまとめる（選択モード）
    issuanceTx['Fee'] = '0';
    escrowCreateTx['Fee'] = '0';
    final batchTx = _batchService.buildBatchTxJson(
      accountAddress: acct,
      modeFlags: _batchMode,
      innerTxs: [
        issuanceTx,
        escrowCreateTx,
      ],
    );

    try {
      final res = await _connector.signAndSubmit(txJson: batchTx);
      setState(() {
        _resultHash = res['result']?['hash'] as String?;
        _events.add(
          SignProgressEvent(
            state: SignProgressState.submitted,
            message: 'Batch submitted: mode=${_batchModeName(_batchMode)} inner=2',
            txHash: _resultHash,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _events.add(
          SignProgressEvent(
            state: SignProgressState.canceled,
            message: 'Batch demo error: $e',
          ),
        );
      });
    }
  }

  Future<void> _signTwoPaymentsBatchDemo() async {
    final acct = _sessionAddress ?? 'rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpRWL';
    final pay1 = {
      'TransactionType': 'Payment',
      'Account': acct,
      'Destination': acct,
      'Amount': '1',
      'Fee': '0',
    };
    final pay2 = {
      'TransactionType': 'Payment',
      'Account': acct,
      'Destination': acct,
      'Amount': '2',
      'Fee': '0',
    };
    final batchTx = _batchService.buildBatchTxJson(
      accountAddress: acct,
      modeFlags: _batchMode,
      innerTxs: [pay1, pay2],
    );
    try {
      final res = await _connector.signAndSubmit(txJson: batchTx);
      setState(() {
        _resultHash = res['result']?['hash'] as String?;
        _events.add(
          SignProgressEvent(
            state: SignProgressState.submitted,
            message: 'Batch submitted: mode=${_batchModeName(_batchMode)} inner=2',
            txHash: _resultHash,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _events.add(
          SignProgressEvent(
            state: SignProgressState.canceled,
            message: 'Batch payments error: $e',
          ),
        );
      });
    }
  }

  void _preflightEscrowDemo() {
    final rMpt = EscrowPreflight.checkMpt(
      tokenCanEscrow: true,
      tokenCanTransfer: false,
      destinationIsIssuerWhenNoTransfer: false,
      sourceHoldsToken: true,
      destinationCanReceive: true,
      sourceLocked: false,
      tokenLockedGlobally: false,
      sourceHasSufficientSpendable: true,
    );
    final rIou = EscrowPreflight.checkIou(
      issuerAllowsTrustLineLocking: true,
      sourceHasTrustline: false,
      destinationTrustlineCreatable: true,
      issuerRequiresAuth: true,
      sourceAuthorized: false,
      destinationAuthorized: true,
      sourceFrozen: false,
      destinationFrozen: false,
      sourceHasSufficientSpendable: true,
    );
    final lines = <String>[];
    lines.add('[MPT] ${rMpt.ok ? 'OK' : 'Issues'}');
    lines.addAll(rMpt.issues.map((e) => '- $e'));
    lines.add('[IOU] ${rIou.ok ? 'OK' : 'Issues'}');
    lines.addAll(rIou.issues.map((e) => '- $e'));
    final text = lines.join('\n');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Escrow Preflight (simulate)'),
        content: SelectableText(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _signBatchFailureDemo() async {
    final acct = _sessionAddress ?? 'rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpRWL';
    final badPayment = {
      'TransactionType': 'Payment',
      'Account': acct,
      'Destination': 'rrrrrrrrrrrrrrrrrrrrrhoLvTp',
      'Amount': '1',
      'Fee': '0',
    };
    final goodPayment = {
      'TransactionType': 'Payment',
      'Account': acct,
      'Destination': acct,
      'Amount': '1',
      'Fee': '0',
    };
    final batchTx = _batchService.buildBatchTxJson(
      accountAddress: acct,
      modeFlags: _batchMode,
      innerTxs: [badPayment, goodPayment],
    );
    try {
      final res = await _connector.signAndSubmit(txJson: batchTx);
      setState(() {
        _resultHash = res['result']?['hash'] as String?;
        _events.add(
          SignProgressEvent(
            state: SignProgressState.submitted,
            message: 'Batch submitted (with failure): mode=${_batchModeName(_batchMode)} inner=2',
            txHash: _resultHash,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _events.add(
          SignProgressEvent(
            state: SignProgressState.canceled,
            message: 'Batch failure demo error: $e',
          ),
        );
      });
    }
  }

  Future<void> _signModeComparisonBatchDemo() async {
    final acct = _sessionAddress ?? 'rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpRWL';
    List<bool> successes = [false, true, true];
    final raw = _batchPreviewPatternCtrl.text.trim();
    if (raw.isNotEmpty) {
      successes = raw
          .split(',')
          .map((s) => s.trim().toUpperCase())
          .map((s) => s == 'T' || s == 'TRUE' || s == '1')
          .toList();
      if (successes.length < 2) successes = [false, true, true];
      if (successes.length > 3) successes = successes.sublist(0, 3);
    }

    Map<String, dynamic> _goodPay(int drops) => {
          'TransactionType': 'Payment',
          'Account': acct,
          'Destination': acct,
          'Amount': '$drops',
          'Fee': '0',
        };
    Map<String, dynamic> _badPay(int drops) => {
          'TransactionType': 'Payment',
          'Account': acct,
          'Destination': 'rrrrrrrrrrrrrrrrrrrrrhoLvTp',
          'Amount': '$drops',
          'Fee': '0',
        };

    final inner = <Map<String, dynamic>>[
      successes.elementAt(0) ? _goodPay(1) : _badPay(1),
      successes.length >= 2 && successes[1] ? _goodPay(2) : _badPay(2),
      successes.length >= 3 && successes[2] ? _goodPay(3) : _badPay(3),
    ];

    final batchTx = _batchService.buildBatchTxJson(
      accountAddress: acct,
      modeFlags: _batchMode,
      innerTxs: inner,
    );

    try {
      final res = await _connector.signAndSubmit(txJson: batchTx);
      final applied = BatchUtils.decideAppliedIndices(
        modeFlags: _batchMode,
        successes: successes,
      );
      setState(() {
        _resultHash = res['result']?['hash'] as String?;
        _events.add(
          SignProgressEvent(
            state: SignProgressState.submitted,
            message:
                'Batch submitted: mode=${_batchModeName(_batchMode)} inner=${inner.length} successes=${successes.map((b) => b ? 'T' : 'F').toList()} applied=${applied.map((b) => b ? '✔' : '✖').toList()}',
            txHash: _resultHash,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _events.add(
          SignProgressEvent(
            state: SignProgressState.canceled,
            message: 'Mode comparison batch error: $e',
          ),
        );
      });
    }
  }

  void _previewModeApplied() {
    List<bool> successes = [false, true, true];
    final raw = _batchPreviewPatternCtrl.text.trim();
    if (raw.isNotEmpty) {
      successes = raw
          .split(',')
          .map((s) => s.trim().toUpperCase())
          .map((s) => s == 'T' || s == 'TRUE' || s == '1')
          .toList();
      if (successes.length < 2) successes = [false, true, true];
    }
    final applied = BatchUtils.decideAppliedIndices(
      modeFlags: _batchMode,
      successes: successes,
    );
    final lines = <String>[
      'Mode: ${_batchModeName(_batchMode)}',
      'Successes: ${successes.map((b) => b ? 'T' : 'F').toList()}',
      'Applied: ${applied.map((b) => b ? '✔' : '✖').toList()}',
    ];
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Batch Applied Preview'),
        content: SelectableText(lines.join('\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _runIouPreflightNetwork() async {
    final src = _sessionAddress ?? 'rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpRWL';
    final dst = _destCtrl.text.trim().isNotEmpty ? _destCtrl.text.trim() : src;
    final issuer = _issuerCtrl.text.trim();
    final currency = _currencyCtrl.text.trim();
    final amount = _amountCtrl.text.trim();
    try {
      final r = await _preflightClient.preflightIou(
        sourceAccount: src,
        destinationAccount: dst,
        issuerAccount: issuer,
        currency: currency,
        requiredAmount: amount,
      );
      final lines = <String>[];
      lines.add('[IOU Preflight] ${r.ok ? 'OK' : 'Issues'}');
      lines.addAll(r.issues.map((e) => '- $e'));
      final text = lines.join('\n');
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('IOU Preflight (network)'),
          content: SelectableText(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('IOU Preflight (network) error'),
          content: SelectableText('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _previewCompressedMptMetadata() {
    final pretty = {
      'ticker': _mptTickerCtrl.text.trim(),
      'name': _mptNameCtrl.text.trim(),
      'asset_class': _mptClassCtrl.text.trim(),
      'issuer_name': _mptIssuerNameCtrl.text.trim(),
      'desc': _mptDescCtrl.text.trim(),
      'icon': _mptIconCtrl.text.trim(),
    };
    final compact = _tokenService.compactMetadata(pretty);
    String hex = '';
    int bytes = 0;
    try {
      final tx = _tokenService.buildMPTIssuanceCreateTxJson(
        accountAddress: _sessionAddress ?? 'rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpRWL',
        assetScale: 2,
        metadataJson: compact,
      );
      hex = (tx['MPTokenMetadata'] as String?) ?? '';
      bytes = hex.length ~/ 2;
    } catch (e) {
      hex = 'Error: $e';
    }
    final lines = <String>[
      'compact: $compact',
      'hex bytes: $bytes',
    ];
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('MPT Metadata (compressed preview)'),
        content: SelectableText(lines.join('\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _signIssueMptBatchFromForm() async {
    final acct = _sessionAddress ?? 'rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpRWL';
    int parseInt(String v, int def) {
      try {
        return int.parse(v.trim());
      } catch (_) {
        return def;
      }
    }
    final compact = _tokenService.compactMetadata({
      'ticker': _mptTickerCtrl.text.trim(),
      'name': _mptNameCtrl.text.trim(),
      'asset_class': _mptClassCtrl.text.trim(),
      'issuer_name': _mptIssuerNameCtrl.text.trim(),
      'desc': _mptDescCtrl.text.trim(),
      'icon': _mptIconCtrl.text.trim(),
    });
    final issuanceTx = _tokenService.buildMPTIssuanceCreateTxJson(
      accountAddress: acct,
      assetScale: 2,
      maxAmount: _mptMaxAmountCtrl.text.trim(),
      transferFee: parseInt(_mptTransferFeeCtrl.text.trim(), 0),
      metadataJson: compact,
      flags: parseInt(_mptFlagsCtrl.text.trim(), 0),
    );
    final finishAfter = _toRippleEpochSeconds(DateTime.now().toUtc().add(const Duration(minutes: 10)));
    final escrowCreateTx = _escrowService.buildEscrowCreateTxJson(
      accountAddress: acct,
      destinationAddress: acct,
      amount: '10',
      finishAfter: finishAfter,
    );
    issuanceTx['Fee'] = '0';
    escrowCreateTx['Fee'] = '0';
    final batchTx = _batchService.buildBatchTxJson(
      accountAddress: acct,
      modeFlags: _batchMode,
      innerTxs: [issuanceTx, escrowCreateTx],
    );
    try {
      final res = await _connector.signAndSubmit(txJson: batchTx);
      setState(() {
        _resultHash = res['result']?['hash'] as String?;
        _events.add(
          SignProgressEvent(
            state: SignProgressState.submitted,
            message: 'Batch submitted: mode=${_batchModeName(_batchMode)} inner=2',
            txHash: _resultHash,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _events.add(
          SignProgressEvent(
            state: SignProgressState.canceled,
            message: 'Issue MPT batch error: $e',
          ),
        );
      });
    }
  }

  void _updateMptFlagsFromToggles() {
    int flags = 0;
    if (_mptFlagCanTransfer) flags |= 1;
    if (_mptFlagRequireAuth) flags |= 2;
    if (_mptFlagCanLock) flags |= 4;
    final current = _mptFlagsCtrl.text.trim();
    int direct = 0;
    try {
      direct = int.parse(current.isEmpty ? '0' : current);
    } catch (_) {
      direct = 0;
    }
    final sum = flags | direct;
    _mptFlagsCtrl.text = '$sum';
  }

  String _batchModeName(int m) {
    if (m == BatchService.tfAllOrNothing) return 'ALLORNOTHING';
    if (m == BatchService.tfOnlyOne) return 'ONLYONE';
    if (m == BatchService.tfUntilFailure) return 'UNTILFAILURE';
    if (m == BatchService.tfIndependent) return 'INDEPENDENT';
    return 'UNKNOWN';
  }
}
