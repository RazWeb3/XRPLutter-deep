// -------------------------------------------------------
// 目的・役割: EscrowServiceのビルダー検証テスト。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'package:test/test.dart';
import 'package:xrplutter_sdk/xrplutter.dart';

void main() {
  test('buildEscrowCreateTxJson requires finishAfter or condition', () {
    final svc = EscrowService();
    expect(
      () => svc.buildEscrowCreateTxJson(
        accountAddress: 'rA',
        destinationAddress: 'rB',
        amount: '100',
      ),
      throwsArgumentError,
    );
  });

  test('buildEscrowCreateTxJson builds XRP escrow with FinishAfter', () {
    final svc = EscrowService();
    final tx = svc.buildEscrowCreateTxJson(
      accountAddress: 'rA',
      destinationAddress: 'rB',
      amount: '100',
      finishAfter: 1234567890,
    );
    expect(tx['TransactionType'], equals('EscrowCreate'));
    expect(tx['Amount'], equals('100'));
    expect(tx['FinishAfter'], equals(1234567890));
  });

  test('buildEscrowCreateTxJson builds IOU escrow with Condition', () {
    final svc = EscrowService();
    final amount = {
      'currency': 'USD',
      'value': '10',
      'issuer': 'rISSUER',
    };
    final tx = svc.buildEscrowCreateTxJson(
      accountAddress: 'rA',
      destinationAddress: 'rB',
      amount: amount,
      conditionHex: 'A0FF',
    );
    expect(tx['Amount'], equals(amount));
    expect(tx['Condition'], equals('A0FF'));
  });

  test('buildEscrowFinishTxJson builds finish tx', () {
    final svc = EscrowService();
    final tx = svc.buildEscrowFinishTxJson(
      accountAddress: 'rB',
      ownerAddress: 'rA',
      offerSequence: 12,
    );
    expect(tx['TransactionType'], equals('EscrowFinish'));
    expect(tx['OfferSequence'], equals(12));
  });
}