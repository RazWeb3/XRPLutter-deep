// -------------------------------------------------------
// 目的・役割: TokenService.compactMetadata のキー圧縮を検証するテスト。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'package:test/test.dart';
import 'package:xrplutter_sdk/xrplutter.dart';

void main() {
  test('compactMetadata maps pretty keys to compressed keys', () {
    final svc = TokenService();
    final pretty = {
      'ticker': 'USTBT',
      'name': 'US Treasury Bill',
      'asset_class': 'rwa',
      'issuer_name': 'US Treasury',
      'desc': 'Short term',
      'icon': 'https://example.com/icon.png',
    };
    final compact = svc.compactMetadata(pretty);
    expect(compact['tickert'], equals('USTBT'));
    expect(compact['namen'], equals('US Treasury Bill'));
    expect(compact['ac'], equals('rwa'));
    expect(compact['in'], equals('US Treasury'));
    expect(compact['d'], equals('Short term'));
    expect(compact['i'], equals('https://example.com/icon.png'));
  });
}