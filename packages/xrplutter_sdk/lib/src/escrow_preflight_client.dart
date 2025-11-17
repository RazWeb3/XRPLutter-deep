// -------------------------------------------------------
// 目的・役割: Escrow事前検証のネットワーク参照版。XRPL RPCからIOU条件を評価する。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'xrpl_client.dart';
import 'escrow_preflight.dart';

typedef RpcCall = Future<Map<String, dynamic>> Function(
  String method,
  Map<String, dynamic> params,
);

class EscrowPreflightClient {
  EscrowPreflightClient({XRPLClient? client, RpcCall? rpc})
      : _client = client ?? XRPLClient(),
        _rpc = rpc;

  final XRPLClient _client;
  final RpcCall? _rpc;

  Future<Map<String, dynamic>> _call(
      String method, Map<String, dynamic> params) async {
    if (_rpc != null) return _rpc(method, params);
    return _client.call(method, params);
  }

  /// IOU用の事前検証（ネットワーク参照）
  /// currency例: 'USD'、requiredAmount例: '10'
  Future<EscrowPreflightResult> preflightIou({
    required String sourceAccount,
    required String destinationAccount,
    required String issuerAccount,
    required String currency,
    required String requiredAmount,
  }) async {
    final issues = <String>[];

    // issuer account flags
    final ai = await _call('account_info', {'account': issuerAccount});
    final flags = (ai['result']?['account_data']?['Flags'] as int?) ?? 0;
    const lsfRequireAuth =
        0x00040000; // issuer requires trustline authorization
    const lsfGlobalFreeze = 0x00400000; // global freeze
    final requireAuth = (flags & lsfRequireAuth) != 0;
    final globalFreeze = (flags & lsfGlobalFreeze) != 0;
    if (globalFreeze) {
      issues.add('Issuer has GlobalFreeze enabled.');
    }

    // source trustline
    final srcLines = await _call(
        'account_lines', {'account': sourceAccount, 'peer': issuerAccount});
    final srcList = (srcLines['result']?['lines'] as List?) ?? const [];
    final srcLine = srcList.cast<Map>().firstWhere(
          (e) => (e['currency']?.toString() ?? '') == currency,
          orElse: () => <String, dynamic>{},
        ) as Map<String, dynamic>;
    final hasSrcTl = srcLine.isNotEmpty;
    if (!hasSrcTl) {
      issues.add('Source lacks trustline to issuer for $currency.');
    }
    final srcAuthorized = (srcLine['authorized'] == true);
    final srcFrozen =
        (srcLine['freeze'] == true) || (srcLine['frozen'] == true);
    if (requireAuth && !srcAuthorized) {
      issues.add('Source is not authorized to hold $currency.');
    }
    if (srcFrozen) {
      issues.add('Source trustline is frozen.');
    }
    // spendable balance check
    double parseAmount(dynamic v) {
      try {
        return double.parse(v.toString());
      } catch (_) {
        return 0.0;
      }
    }

    final srcBalance = parseAmount(srcLine['balance'] ?? '0');
    final reqAmt = parseAmount(requiredAmount);
    if (srcBalance < reqAmt) {
      issues.add('Insufficient source balance: $srcBalance < $reqAmt.');
    }

    // destination trustline (must exist or be creatable by destination)
    final dstLines = await _call('account_lines',
        {'account': destinationAccount, 'peer': issuerAccount});
    final dstList = (dstLines['result']?['lines'] as List?) ?? const [];
    final dstLine = dstList.cast<Map>().firstWhere(
          (e) => (e['currency']?.toString() ?? '') == currency,
          orElse: () => <String, dynamic>{},
        ) as Map<String, dynamic>;
    final hasDstTl = dstLine.isNotEmpty;
    final dstAuthorized = (dstLine['authorized'] == true);
    final dstFrozen =
        (dstLine['freeze'] == true) || (dstLine['frozen'] == true);
    if (requireAuth && !dstAuthorized) {
      issues.add('Destination is not authorized to hold $currency.');
    }
    if (dstFrozen) {
      issues.add('Destination trustline is frozen.');
    }
    if (!hasDstTl) {
      issues.add('Destination lacks trustline to issuer for $currency.');
    }

    return EscrowPreflightResult(issues.isEmpty, issues);
  }
}
