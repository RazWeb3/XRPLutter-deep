// -------------------------------------------------------
// 目的・役割: MPT（Multi-Purpose Tokens）発行などトークナイゼーション操作の高レベルAPIを提供する。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'dart:convert';
import 'xrpl_client.dart';

class TokenService {
  TokenService({XRPLClient? client}) : _client = client ?? XRPLClient();
  final XRPLClient _client;
  XRPLClient get client => _client;

  Map<String, dynamic>? _lastIssuancePreview;
  Map<String, dynamic>? get lastIssuancePreview => _lastIssuancePreview;

  /// MPTokenIssuanceCreate tx_json を構築（署名前プレビュー用）
  /// 必須: Account, AssetScale
  /// 任意: MaxAmount, TransferFee, MPTokenMetadata(hex), Flags（発行設定ビットフィールド）
  Map<String, dynamic> buildMPTIssuanceCreateTxJson({
    required String accountAddress,
    required int assetScale,
    String? maxAmount,
    int? transferFee,
    Map<String, dynamic>? metadataJson,
    int? flags,
  }) {
    if (assetScale < 0 || assetScale > 255) {
      throw ArgumentError('AssetScaleは0〜255の範囲で指定してください。');
    }

    final tx = <String, dynamic>{
      'TransactionType': 'MPTokenIssuanceCreate',
      'Account': accountAddress,
      'AssetScale': assetScale,
      'Fee': '10',
    };
    if (maxAmount != null && maxAmount.isNotEmpty) {
      tx['MaxAmount'] = maxAmount;
    }
    if (transferFee != null) {
      if (transferFee < 0) {
        throw ArgumentError('TransferFeeは0以上で指定してください。');
      }
      tx['TransferFee'] = transferFee;
    }
    if (metadataJson != null && metadataJson.isNotEmpty) {
      final hex = _encodeJsonToHex(metadataJson);
      tx['MPTokenMetadata'] = hex;
    }
    if (flags != null) {
      tx['Flags'] = flags;
    }

    _lastIssuancePreview = tx;
    return tx;
  }

  Map<String, dynamic> compactMetadata(Map<String, dynamic> pretty) {
    final out = <String, dynamic>{};
    void put(String k, dynamic v) {
      if (v == null) return;
      if (v is String && v.isEmpty) return;
      out[k] = v;
    }
    put('tickert', pretty['ticker'] ?? pretty['tickert']);
    put('namen', pretty['name'] ?? pretty['namen']);
    put('d', pretty['desc'] ?? pretty['d']);
    put('i', pretty['icon'] ?? pretty['i']);
    put('ac', pretty['asset_class'] ?? pretty['ac']);
    put('as', pretty['asset_subclass'] ?? pretty['as']);
    put('in', pretty['issuer_name'] ?? pretty['in']);
    put('us', pretty['uris'] ?? pretty['us']);
    put('ai', pretty['additional_info'] ?? pretty['ai']);
    return out;
  }

  String _encodeJsonToHex(Map<String, dynamic> jsonObj) {
    final jsonStr = json.encode(jsonObj);
    final bytes = utf8.encode(jsonStr);
    if (bytes.length > 1024) {
      throw ArgumentError('MPTokenMetadataは最大1024バイトまでです。現在: ${bytes.length}バイト');
    }
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}