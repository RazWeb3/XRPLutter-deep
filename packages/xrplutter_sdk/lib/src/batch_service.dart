// -------------------------------------------------------
// 目的・役割: Batch（XLS-56）トランザクションの構築支援。複数txの原子的実行を高レベルAPIで提供する。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'xrpl_client.dart';

class BatchService {
  BatchService({XRPLClient? client}) : _client = client ?? XRPLClient();
  final XRPLClient _client;

  // Flags（モード）
  static const int tfAllOrNothing = 0x00010000;
  static const int tfOnlyOne = 0x00020000;
  static const int tfUntilFailure = 0x00040000;
  static const int tfIndependent = 0x00080000;

  Map<String, dynamic>? _lastBatchPreview;
  Map<String, dynamic>? get lastBatchPreview => _lastBatchPreview;

  /// Batchトランザクションのtx_jsonを構築（RawTransactionsは未署名かつFeeゼロ推奨）
  /// modeFlags: 上記4種のいずれかを指定
  Map<String, dynamic> buildBatchTxJson({
    required String accountAddress,
    required int modeFlags,
    required List<Map<String, dynamic>> innerTxs,
    List<Map<String, dynamic>>? batchSigners,
    bool enforceZeroFees = true,
  }) {
    if (innerTxs.length < 2 || innerTxs.length > 8) {
      throw ArgumentError('Batchは2〜8件のトランザクションを含める必要があります。現在: ${innerTxs.length}件');
    }
    if (enforceZeroFees) {
      for (final t in innerTxs) {
        final fee = t['Fee'];
        if (fee == null) {
          throw ArgumentError('Inner txにFeeがありません。Fee="0"を推奨します。');
        }
        if (fee is String) {
          if (fee != '0') {
            throw ArgumentError('Inner txのFeeは"0"である必要があります。実値: $fee');
          }
        } else if (fee is num) {
          if (fee != 0) {
            throw ArgumentError('Inner txのFeeは0である必要があります。実値: $fee');
          }
        } else {
          throw ArgumentError('Inner txのFee形式が不正です。');
        }
      }
    }

    final tx = <String, dynamic>{
      'TransactionType': 'Batch',
      'Account': accountAddress,
      'Flags': modeFlags,
      'RawTransactions': innerTxs,
      'Fee': '20',
    };
    if (batchSigners != null && batchSigners.isNotEmpty) {
      tx['BatchSigners'] = batchSigners;
    }
    _lastBatchPreview = tx;
    return tx;
  }
}