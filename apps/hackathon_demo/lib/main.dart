// -------------------------------------------------------
// 目的・役割: ハッカソン提出用のシンプルで直感的なXRPLデモUI（Flutter Web）。
// 作成日: 2025/11/17
//
// 更新履歴:
// 2025/11/17 13:20 新規作成: MPT発行/圧縮メタデータ可視化、Escrow、Batch比較、IOU事前検証を統合した簡易UIを実装。
// 理由: ハッカソン評価に適した「一目で理解・操作できる」体験を提供するため。
// -------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xrplutter_sdk/xrplutter.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(const HackathonApp());
}

class HackathonApp extends StatelessWidget {
  const HackathonApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XRPLutter Hackathon Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const HackathonHome(),
    );
  }
}

class HackathonHome extends StatefulWidget {
  const HackathonHome({super.key});
  @override
  State<HackathonHome> createState() => _HackathonHomeState();
}

class _HackathonHomeState extends State<HackathonHome> {
  final DateFormat _dateFmt = DateFormat('HH:mm:ss');
  final XRPLClient _client = XRPLClient(timeout: const Duration(seconds: 12), maxRetries: 3, retryBaseDelayMs: 300);
  late final TokenService _tokenService = TokenService(client: _client);
  late final EscrowService _escrowService = EscrowService(client: _client);
  late final BatchService _batchService = BatchService(client: _client);
  late final EscrowPreflightClient _preflightClient = EscrowPreflightClient(client: _client);
  WalletConnector _connector = WalletConnector();

  String? _sessionAddress;
  String? _resultHash;
  String? _lastError;
  int _batchMode = BatchService.tfAllOrNothing;
  final List<SignProgressEvent> _events = [];

  final TextEditingController _ticker = TextEditingController(text: 'USTBT');
  final TextEditingController _name = TextEditingController(text: 'US Treasury Bill');
  final TextEditingController _aclass = TextEditingController(text: 'rwa');
  final TextEditingController _issuerName = TextEditingController(text: 'US Treasury');
  final TextEditingController _desc = TextEditingController(text: 'Short term debt');
  final TextEditingController _icon = TextEditingController(text: 'https://example.com/icon.png');
  final TextEditingController _maxAmount = TextEditingController(text: '1000000');
  final TextEditingController _transferFee = TextEditingController(text: '100');
  bool _flagCanTransfer = true;
  bool _flagRequireAuth = false;
  bool _flagCanLock = false;
  final TextEditingController _flagsNumeric = TextEditingController(text: '1');

  final TextEditingController _issuerCtrl = TextEditingController(text: 'rISSUER_EXAMPLE');
  final TextEditingController _currencyCtrl = TextEditingController(text: 'USD');
  final TextEditingController _amountCtrl = TextEditingController(text: '10');
  final TextEditingController _destCtrl = TextEditingController(text: '');

  final TextEditingController _patternCtrl = TextEditingController(text: 'F,T,T');
  final TextEditingController _xamanProxyController = TextEditingController(text: '');
  final TextEditingController _jwtController = TextEditingController(text: '');

  StreamSubscription<SignProgressEvent>? _progressSub;

  @override
  void initState() {
    super.initState();
    _connector = WalletConnector(client: _client);
    _progressSub = _connector.progressStream.listen((e) {
      setState(() {
        _events.add(e);
        if (e.txHash != null) _resultHash = e.txHash;
        if (e.state == SignProgressState.error) _lastError = e.message;
      });
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  Future<void> _connect(WalletProvider p) async {
    Uri? xamanBase;
    final raw = _xamanProxyController.text.trim();
    if (raw.isNotEmpty) {
      try {
        final u = Uri.parse(raw);
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

    _connector = WalletConnector(
      config: WalletConnectorConfig(
        xamanProxyBaseUrl: xamanBase,
        jwtBearerToken: _jwtController.text.trim().isNotEmpty ? _jwtController.text.trim() : null,
        httpTimeout: const Duration(seconds: 10),
        signingTimeout: const Duration(seconds: 90),
      ),
      client: _client,
    );
    await _progressSub?.cancel();
    _progressSub = _connector.progressStream.listen((e) {
      setState(() {
        _events.add(e);
        if (e.txHash != null) _resultHash = e.txHash;
        if (e.state == SignProgressState.error) _lastError = e.message;
      });
    });
    await _connector.connect(provider: p);
    try {
      final info = await _connector.getAccountInfo();
      _sessionAddress = info.address;
    } catch (_) {}
    setState(() {});
  }

  String _compressedPreview() {
    final compact = _tokenService.compactMetadata({
      'ticker': _ticker.text.trim(),
      'name': _name.text.trim(),
      'asset_class': _aclass.text.trim(),
      'issuer_name': _issuerName.text.trim(),
      'desc': _desc.text.trim(),
      'icon': _icon.text.trim(),
    });
    final jsonStr = json.encode(compact);
    final bytes = utf8.encode(jsonStr).length;
    return 'compact: $compact\nbytes: $bytes';
  }

  void _syncFlagsNumeric() {
    int flags = 0;
    if (_flagCanTransfer) flags |= 1;
    if (_flagRequireAuth) flags |= 2;
    if (_flagCanLock) flags |= 4;
    int direct = 0;
    try {
      final v = _flagsNumeric.text.trim();
      direct = int.parse(v.isEmpty ? '0' : v);
    } catch (_) {}
    _flagsNumeric.text = '${flags | direct}';
  }

  int _toRippleEpochSeconds(DateTime dt) {
    final unix = dt.toUtc().millisecondsSinceEpoch ~/ 1000;
    return unix - 946684800;
  }

  Future<void> _issueMptAndEscrowBatch() async {
    final acct = _sessionAddress ?? 'rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpRWL';
    final issuanceTx = _tokenService.buildMPTIssuanceCreateTxJson(
      accountAddress: acct,
      assetScale: 2,
      maxAmount: _maxAmount.text.trim(),
      transferFee: int.tryParse(_transferFee.text.trim()) ?? 0,
      metadataJson: _tokenService.compactMetadata({
        'ticker': _ticker.text.trim(),
        'name': _name.text.trim(),
        'asset_class': _aclass.text.trim(),
        'issuer_name': _issuerName.text.trim(),
        'desc': _desc.text.trim(),
        'icon': _icon.text.trim(),
      }),
      flags: int.tryParse(_flagsNumeric.text.trim()) ?? 0,
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
      setState(() => _resultHash = res['result']?['hash'] as String?);
    } catch (e) {
      setState(() => _lastError = '$e');
    }
  }

  Future<void> _runIouPreflight() async {
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
      final lines = <String>['[IOU Preflight] ${r.ok ? 'OK' : 'Issues'}', ...r.issues.map((e) => '- $e')];
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(title: const Text('IOU Preflight'), content: SelectableText(lines.join('\n')), actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close'))]),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(title: const Text('IOU Preflight error'), content: SelectableText('$e'), actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close'))]),
      );
    }
  }

  void _previewApplied() {
    List<bool> successes = [false, true, true];
    final raw = _patternCtrl.text.trim();
    if (raw.isNotEmpty) {
      successes = raw.split(',').map((s) => s.trim().toUpperCase()).map((s) => s == 'T' || s == 'TRUE' || s == '1').toList();
      if (successes.length < 2) successes = [false, true, true];
    }
    final applied = BatchUtils.decideAppliedIndices(modeFlags: _batchMode, successes: successes);
    final lines = <String>[
      'Mode: ${_batchModeName(_batchMode)}',
      'Successes: ${successes.map((b) => b ? 'T' : 'F').toList()}',
      'Applied: ${applied.map((b) => b ? '✔' : '✖').toList()}',
    ];
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Batch Applied Preview'), content: SelectableText(lines.join('\n')), actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close'))]));
  }

  Future<void> _runModeComparison() async {
    final acct = _sessionAddress ?? 'rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpRWL';
    List<bool> successes = [false, true, true];
    final raw = _patternCtrl.text.trim();
    if (raw.isNotEmpty) {
      successes = raw.split(',').map((s) => s.trim().toUpperCase()).map((s) => s == 'T' || s == 'TRUE' || s == '1').toList();
      if (successes.length < 2) successes = [false, true, true];
      if (successes.length > 3) successes = successes.sublist(0, 3);
    }
    Map<String, dynamic> good(int drops) => {'TransactionType': 'Payment', 'Account': acct, 'Destination': acct, 'Amount': '$drops', 'Fee': '0'};
    Map<String, dynamic> bad(int drops) => {'TransactionType': 'Payment', 'Account': acct, 'Destination': 'rrrrrrrrrrrrrrrrrrrrrhoLvTp', 'Amount': '$drops', 'Fee': '0'};
    final inner = <Map<String, dynamic>>[
      successes[0] ? good(1) : bad(1),
      successes.length >= 2 && successes[1] ? good(2) : bad(2),
      successes.length >= 3 && successes[2] ? good(3) : bad(3),
    ];
    final batchTx = _batchService.buildBatchTxJson(accountAddress: acct, modeFlags: _batchMode, innerTxs: inner);
    try {
      final res = await _connector.signAndSubmit(txJson: batchTx);
      final applied = BatchUtils.decideAppliedIndices(modeFlags: _batchMode, successes: successes);
      setState(() => _resultHash = res['result']?['hash'] as String?);
      final lines = [
        'Submitted: ${_batchModeName(_batchMode)} inner=${inner.length}',
        'Successes: ${successes.map((b) => b ? 'T' : 'F').toList()}',
        'Applied: ${applied.map((b) => b ? '✔' : '✖').toList()}',
        if (_resultHash != null) 'Result hash: $_resultHash',
      ];
      if (!mounted) return;
      showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Batch Summary'), content: SelectableText(lines.join('\n')), actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close'))]));
    } catch (e) {
      setState(() => _lastError = '$e');
    }
  }

  String _batchModeName(int m) {
    if (m == BatchService.tfAllOrNothing) return 'ALLORNOTHING';
    if (m == BatchService.tfOnlyOne) return 'ONLYONE';
    if (m == BatchService.tfUntilFailure) return 'UNTILFAILURE';
    if (m == BatchService.tfIndependent) return 'INDEPENDENT';
    return 'UNKNOWN';
  }

  @override
  Widget build(BuildContext context) {
    final header = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('XRPLutter Hackathon Demo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('1) 接続  2) メタデータ圧縮  3) Flags設定  4) Issue+Escrow (Batch)  5) モード比較/事前検証'),
    ]);

    final connectCard = Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Step 1: ウォレット接続'),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ElevatedButton.icon(onPressed: () => _connect(WalletProvider.xaman), icon: const Icon(Icons.qr_code), label: const Text('Connect Xaman')),
        ElevatedButton.icon(onPressed: () => _connect(WalletProvider.walletconnect), icon: const Icon(Icons.link), label: const Text('Connect WalletConnect')),
        ElevatedButton.icon(onPressed: () => _connect(WalletProvider.crossmark), icon: const Icon(Icons.extension), label: const Text('Connect Crossmark')),
        ElevatedButton.icon(onPressed: () => _connect(WalletProvider.gemwallet), icon: const Icon(Icons.diamond), label: const Text('Connect GemWallet')),
      ]),
      const SizedBox(height: 8),
      Text('Session address: ${_sessionAddress ?? '-'}'),
    ])));

    final metadataCard = Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Step 2: 圧縮メタデータ（XLS-89）'),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextField(controller: _ticker, decoration: const InputDecoration(labelText: 'ticker', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: _name, decoration: const InputDecoration(labelText: 'name', border: OutlineInputBorder()))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextField(controller: _aclass, decoration: const InputDecoration(labelText: 'asset_class', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: _issuerName, decoration: const InputDecoration(labelText: 'issuer_name', border: OutlineInputBorder()))),
      ]),
      const SizedBox(height: 8),
      TextField(controller: _desc, decoration: const InputDecoration(labelText: 'desc', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(controller: _icon, decoration: const InputDecoration(labelText: 'icon (URL)', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(onPressed: () {
        final text = _compressedPreview();
        showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Compressed Preview'), content: SelectableText(text), actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close'))]));
      }, icon: const Icon(Icons.compress), label: const Text('Preview'))),
    ])));

    final flagsCard = Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Step 3: Issuance Flags'),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: SwitchListTile(title: const Text('CanTransfer'), value: _flagCanTransfer, onChanged: (v) { setState(() { _flagCanTransfer = v; _syncFlagsNumeric(); }); })),
        Expanded(child: SwitchListTile(title: const Text('RequireAuth'), value: _flagRequireAuth, onChanged: (v) { setState(() { _flagRequireAuth = v; _syncFlagsNumeric(); }); })),
        Expanded(child: SwitchListTile(title: const Text('CanLock'), value: _flagCanLock, onChanged: (v) { setState(() { _flagCanLock = v; _syncFlagsNumeric(); }); })),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextField(controller: _maxAmount, decoration: const InputDecoration(labelText: 'MaxAmount', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: _transferFee, decoration: const InputDecoration(labelText: 'TransferFee (100=0.01%)', border: OutlineInputBorder()))),
      ]),
      const SizedBox(height: 8),
      TextField(controller: _flagsNumeric, decoration: const InputDecoration(labelText: 'Issuance Flags (numeric)', helperText: 'トグル＋直接入力の合算値', border: OutlineInputBorder())),
    ])));

    final escrowCard = Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Step 4: Escrow（FinishAfter付き）'),
      const SizedBox(height: 8),
      ElevatedButton.icon(onPressed: _issueMptAndEscrowBatch, icon: const Icon(Icons.token), label: const Text('Issue MPT + Escrow (Batch)')),
    ])));

    final preflightCard = Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('IOU事前検証（ネット参照）'),
      const SizedBox(height: 8),
      TextField(controller: _issuerCtrl, decoration: const InputDecoration(labelText: 'Issuer account', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextField(controller: _currencyCtrl, decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Required amount', border: OutlineInputBorder()))),
      ]),
      const SizedBox(height: 8),
      TextField(controller: _destCtrl, decoration: const InputDecoration(labelText: 'Destination (optional)', helperText: '未入力ならセッションアドレス', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(onPressed: _runIouPreflight, icon: const Icon(Icons.security), label: const Text('Run IOU preflight'))),
    ])));

    final proxyCard = Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Proxy 設定（Xaman最小構成）'),
      const SizedBox(height: 8),
      TextField(controller: _xamanProxyController, decoration: const InputDecoration(labelText: 'Xaman Proxy Base URL', hintText: 'https://<your-vercel-app>/xumm/v1/', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(controller: _jwtController, obscureText: true, enableSuggestions: false, autocorrect: false, decoration: const InputDecoration(labelText: 'JWT Bearer Token', hintText: '例: dev-secret で署名したJWT', border: OutlineInputBorder())),
    ])));

    final batchCard = Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Batch（原子的な複数操作）'),
      const SizedBox(height: 8),
      DropdownButton<int>(value: _batchMode, items: const [
        DropdownMenuItem(value: BatchService.tfAllOrNothing, child: Text('ALLORNOTHING')),
        DropdownMenuItem(value: BatchService.tfOnlyOne, child: Text('ONLYONE')),
        DropdownMenuItem(value: BatchService.tfUntilFailure, child: Text('UNTILFAILURE')),
        DropdownMenuItem(value: BatchService.tfIndependent, child: Text('INDEPENDENT')),
      ], onChanged: (v) => setState(() => _batchMode = v ?? _batchMode)),
      const SizedBox(height: 8),
      Row(children: [
        SizedBox(width: 160, child: TextField(controller: _patternCtrl, decoration: const InputDecoration(labelText: 'Success pattern', hintText: 'F,T,T', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        OutlinedButton.icon(onPressed: _previewApplied, icon: const Icon(Icons.visibility), label: const Text('Preview Applied')),
        const SizedBox(width: 8),
        ElevatedButton.icon(onPressed: _runModeComparison, icon: const Icon(Icons.compare_arrows), label: const Text('Run Mode Comparison')),
      ]),
    ])));

    final logsCard = Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Summary'),
      const SizedBox(height: 6),
      if (_resultHash != null) Text('Result hash: $_resultHash'),
      if (_lastError != null) Text('Error: $_lastError', style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 8),
      Container(
        height: 220,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: ListView.builder(
          itemCount: _events.length,
          itemExtent: 56,
          addAutomaticKeepAlives: false,
          cacheExtent: 0,
          itemBuilder: (context, i) {
            final e = _events[i];
            final ts = _dateFmt.format(e.timestamp.toLocal());
            return ListTile(
              leading: Icon(_iconForState(e.state)),
              title: Text(e.state.name),
              subtitle: Text([e.message, ts].where((x) => (x ?? '').isNotEmpty).join(' | ')),
              trailing: e.txHash != null ? Text(e.txHash!) : null,
            );
          },
        ),
      ),
    ])));

    return Scaffold(
      appBar: AppBar(title: const Text('XRPLutter Hackathon Demo')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            header,
            const SizedBox(height: 12),
            connectCard,
            const SizedBox(height: 12),
            proxyCard,
            const SizedBox(height: 12),
            metadataCard,
            const SizedBox(height: 12),
            flagsCard,
            const SizedBox(height: 12),
            escrowCard,
            const SizedBox(height: 12),
            preflightCard,
            const SizedBox(height: 12),
            batchCard,
            const SizedBox(height: 12),
            logsCard,
          ]),
        ),
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
}
