// -------------------------------------------------------
// 目的・役割: TokenServiceのMPT発行txビルダー検証テスト。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'package:test/test.dart';
import 'package:xrplutter_sdk/xrplutter.dart';

void main() {
  test('buildMPTIssuanceCreateTxJson builds minimal tx', () {
    final svc = TokenService();
    final tx = svc.buildMPTIssuanceCreateTxJson(
      accountAddress: 'rTEST',
      assetScale: 2,
    );
    expect(tx['TransactionType'], equals('MPTokenIssuanceCreate'));
    expect(tx['Account'], equals('rTEST'));
    expect(tx['AssetScale'], equals(2));
  });

  test('metadata encodes to hex and enforces size', () {
    final svc = TokenService();
    final tx = svc.buildMPTIssuanceCreateTxJson(
      accountAddress: 'rTEST',
      assetScale: 2,
      metadataJson: {
        'namen': 'US Treasury Bill Token',
        'tickert': 'USTBT',
      },
    );
    final meta = tx['MPTokenMetadata'] as String?;
    expect(meta, isNotNull);
    expect(meta!.isNotEmpty, isTrue);

    final big = 'a' * 1025; // 1025 bytes when utf8
    expect(
      () => svc.buildMPTIssuanceCreateTxJson(
        accountAddress: 'rTEST',
        assetScale: 0,
        metadataJson: {'x': big},
      ),
      throwsArgumentError,
    );
  });
}