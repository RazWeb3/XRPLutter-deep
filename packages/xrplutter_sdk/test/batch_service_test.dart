// -------------------------------------------------------
// 目的・役割: BatchServiceのビルダー検証テスト。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'package:test/test.dart';
import 'package:xrplutter_sdk/xrplutter.dart';

void main() {
  test('buildBatchTxJson enforces inner tx count', () {
    final svc = BatchService();
    final inner = [
      {
        'TransactionType': 'Payment',
        'Account': 'rA',
        'Destination': 'rB',
        'Amount': '1',
        'Fee': '0',
      },
    ];
    expect(
      () => svc.buildBatchTxJson(
        accountAddress: 'rA',
        modeFlags: BatchService.tfAllOrNothing,
        innerTxs: inner,
      ),
      throwsArgumentError,
    );

  final okInner = [
      {
        'TransactionType': 'Payment',
        'Account': 'rA',
        'Destination': 'rB',
        'Amount': '1',
        'Fee': '0',
      },
      {
        'TransactionType': 'OfferCreate',
        'Account': 'rA',
        'Fee': '0',
      },
    ];
    final tx = svc.buildBatchTxJson(
      accountAddress: 'rA',
      modeFlags: BatchService.tfAllOrNothing,
      innerTxs: okInner,
    );
    expect(tx['TransactionType'], equals('Batch'));
    expect((tx['RawTransactions'] as List).length, equals(2));
  });

  test('buildBatchTxJson enforces zero inner fees by default', () {
    final svc = BatchService();
    final inner = [
      {
        'TransactionType': 'Payment',
        'Account': 'rA',
        'Destination': 'rB',
        'Amount': '1',
        'Fee': '10',
      },
      {
        'TransactionType': 'OfferCreate',
        'Account': 'rA',
        'Fee': '0',
      },
    ];
    expect(
      () => svc.buildBatchTxJson(
        accountAddress: 'rA',
        modeFlags: BatchService.tfIndependent,
        innerTxs: inner,
      ),
      throwsArgumentError,
    );
  });

  test('buildBatchTxJson allows non-zero inner fees when disabled', () {
    final svc = BatchService();
    final inner = [
      {
        'TransactionType': 'Payment',
        'Account': 'rA',
        'Destination': 'rB',
        'Amount': '1',
        'Fee': '10',
      },
      {
        'TransactionType': 'OfferCreate',
        'Account': 'rA',
        'Fee': '0',
      },
    ];
    final tx = svc.buildBatchTxJson(
      accountAddress: 'rA',
      modeFlags: BatchService.tfIndependent,
      innerTxs: inner,
      enforceZeroFees: false,
    );
    expect(tx['TransactionType'], equals('Batch'));
  });
}