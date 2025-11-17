// -------------------------------------------------------
// 目的・役割: Payment（XRP/IOU/MPT対応）のtx_jsonビルダーを提供する高レベルAPI。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'xrpl_client.dart';

class PaymentService {
  PaymentService({XRPLClient? client}) : _client = client ?? XRPLClient();
  final XRPLClient _client;

  Map<String, dynamic>? _lastPaymentPreview;
  Map<String, dynamic>? get lastPaymentPreview => _lastPaymentPreview;

  /// 基本的なPayment tx_jsonを構築
  /// amount: XRPなら文字列ドロップ、IOU/MPTはオブジェクト
  Map<String, dynamic> buildPaymentTxJson({
    required String accountAddress,
    required String destinationAddress,
    required dynamic amount,
    String? sendMax,
    String? deliverMin,
    int? flags,
  }) {
    final tx = <String, dynamic>{
      'TransactionType': 'Payment',
      'Account': accountAddress,
      'Destination': destinationAddress,
      'Amount': amount,
      'Fee': '10',
    };
    if (sendMax != null && sendMax.isNotEmpty) {
      tx['SendMax'] = sendMax;
    }
    if (deliverMin != null && deliverMin.isNotEmpty) {
      tx['DeliverMin'] = deliverMin;
    }
    if (flags != null) {
      tx['Flags'] = flags;
    }
    _lastPaymentPreview = tx;
    return tx;
  }
}