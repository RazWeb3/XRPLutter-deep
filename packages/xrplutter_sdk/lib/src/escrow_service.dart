// -------------------------------------------------------
// 目的・役割: Escrow（XRP/IOU/MPT対応）のtx_jsonビルダーを提供する高レベルAPI。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'xrpl_client.dart';

class EscrowService {
  EscrowService({XRPLClient? client}) : _client = client ?? XRPLClient();
  final XRPLClient _client;
  XRPLClient get client => _client;

  Map<String, dynamic>? _lastCreatePreview;
  Map<String, dynamic>? _lastFinishPreview;
  Map<String, dynamic>? get lastCreatePreview => _lastCreatePreview;
  Map<String, dynamic>? get lastFinishPreview => _lastFinishPreview;

  /// EscrowCreate tx_json を構築（XRP/IOU/MPT対応）
  /// amount: XRPなら文字列ドロップ、IOU/MPTはオブジェクトをそのまま渡す
  Map<String, dynamic> buildEscrowCreateTxJson({
    required String accountAddress,
    required String destinationAddress,
    required dynamic amount,
    int? finishAfter,
    int? cancelAfter,
    String? conditionHex,
  }) {
    if (finishAfter == null && conditionHex == null) {
      throw ArgumentError('EscrowCreateにはFinishAfterまたはConditionのいずれかが必要です。');
    }
    final tx = <String, dynamic>{
      'TransactionType': 'EscrowCreate',
      'Account': accountAddress,
      'Destination': destinationAddress,
      'Amount': amount,
      'Fee': '10',
      if (finishAfter != null) 'FinishAfter': finishAfter,
      if (cancelAfter != null) 'CancelAfter': cancelAfter,
      if (conditionHex != null && conditionHex.isNotEmpty) 'Condition': conditionHex,
    };
    _lastCreatePreview = tx;
    return tx;
  }

  /// EscrowFinish tx_json を構築
  Map<String, dynamic> buildEscrowFinishTxJson({
    required String accountAddress,
    required String ownerAddress,
    required int offerSequence,
    String? fulfillmentHex,
    String? conditionHex,
  }) {
    final tx = <String, dynamic>{
      'TransactionType': 'EscrowFinish',
      'Account': accountAddress,
      'Owner': ownerAddress,
      'OfferSequence': offerSequence,
      'Fee': '10',
      if (fulfillmentHex != null && fulfillmentHex.isNotEmpty) 'Fulfillment': fulfillmentHex,
      if (conditionHex != null && conditionHex.isNotEmpty) 'Condition': conditionHex,
    };
    _lastFinishPreview = tx;
    return tx;
  }
}