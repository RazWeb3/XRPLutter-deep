// -------------------------------------------------------
// 目的・役割: PaymentServiceのビルダー検証テスト。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'package:test/test.dart';
import 'package:xrplutter_sdk/xrplutter.dart';

void main() {
  test('buildPaymentTxJson builds XRP payment', () {
    final svc = PaymentService();
    final tx = svc.buildPaymentTxJson(
      accountAddress: 'rA',
      destinationAddress: 'rB',
      amount: '10',
    );
    expect(tx['TransactionType'], equals('Payment'));
    expect(tx['Amount'], equals('10'));
  });

  test('buildPaymentTxJson accepts IOU amount object', () {
    final svc = PaymentService();
    final iou = {
      'currency': 'USD',
      'value': '1',
      'issuer': 'rISSUER',
    };
    final tx = svc.buildPaymentTxJson(
      accountAddress: 'rA',
      destinationAddress: 'rB',
      amount: iou,
    );
    expect(tx['Amount'], equals(iou));
  });
}