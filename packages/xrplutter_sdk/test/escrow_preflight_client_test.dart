// -------------------------------------------------------
// 目的・役割: EscrowPreflightClient（IOU）のネットワーク参照ロジックをスタブで検証。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'package:test/test.dart';
import 'package:xrplutter_sdk/xrplutter.dart';

Future<Map<String, dynamic>> _stubRpc(String method, Map<String, dynamic> params) async {
  switch (method) {
    case 'account_info':
      return {
        'result': {
          'account_data': {
            'Flags': 0x00040000, // RequireAuth
          }
        }
      };
    case 'account_lines':
      final account = params['account'] as String?;
      final peer = params['peer'] as String?;
      if (account == 'rSRC' && peer == 'rISSUER') {
        return {
          'result': {
            'lines': [
              {'currency': 'USD', 'balance': '12', 'authorized': true}
            ]
          }
        };
      }
      if (account == 'rDST' && peer == 'rISSUER') {
        return {
          'result': {
            'lines': [
              {'currency': 'USD', 'balance': '0', 'authorized': true}
            ]
          }
        };
      }
      return {'result': {'lines': []}};
    default:
      return {'result': {}};
  }
}

void main() {
  test('preflightIou passes with auth and balances', () async {
    final client = EscrowPreflightClient(rpc: _stubRpc);
    final r = await client.preflightIou(
      sourceAccount: 'rSRC',
      destinationAccount: 'rDST',
      issuerAccount: 'rISSUER',
      currency: 'USD',
      requiredAmount: '10',
    );
    expect(r.ok, isTrue);
    expect(r.issues, isEmpty);
  });

  test('preflightIou fails when source lacks trustline', () async {
    final client = EscrowPreflightClient(rpc: _stubRpc);
    final r = await client.preflightIou(
      sourceAccount: 'rNO_TL',
      destinationAccount: 'rDST',
      issuerAccount: 'rISSUER',
      currency: 'USD',
      requiredAmount: '1',
    );
    expect(r.ok, isFalse);
    expect(r.issues, anyElement(contains('Source lacks trustline')));
  });
}