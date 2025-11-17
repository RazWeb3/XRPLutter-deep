// -------------------------------------------------------
// 目的・役割: EscrowPreflight（IOU/MPT）の事前検証ロジックをテスト。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'package:test/test.dart';
import 'package:xrplutter_sdk/xrplutter.dart';

void main() {
  test('IOU preflight passes when all conditions satisfied', () {
    final r = EscrowPreflight.checkIou(
      issuerAllowsTrustLineLocking: true,
      sourceHasTrustline: true,
      destinationTrustlineCreatable: true,
      issuerRequiresAuth: true,
      sourceAuthorized: true,
      destinationAuthorized: true,
      sourceFrozen: false,
      destinationFrozen: false,
      sourceHasSufficientSpendable: true,
    );
    expect(r.ok, isTrue);
    expect(r.issues, isEmpty);
  });

  test('IOU preflight reports multiple issues', () {
    final r = EscrowPreflight.checkIou(
      issuerAllowsTrustLineLocking: false,
      sourceHasTrustline: false,
      destinationTrustlineCreatable: false,
      issuerRequiresAuth: true,
      sourceAuthorized: false,
      destinationAuthorized: false,
      sourceFrozen: true,
      destinationFrozen: true,
      sourceHasSufficientSpendable: false,
    );
    expect(r.ok, isFalse);
    expect(r.issues.length, greaterThanOrEqualTo(5));
  });

  test('MPT preflight passes when all conditions satisfied', () {
    final r = EscrowPreflight.checkMpt(
      tokenCanEscrow: true,
      tokenCanTransfer: true,
      destinationIsIssuerWhenNoTransfer: true,
      sourceHoldsToken: true,
      destinationCanReceive: true,
      sourceLocked: false,
      tokenLockedGlobally: false,
      sourceHasSufficientSpendable: true,
    );
    expect(r.ok, isTrue);
    expect(r.issues, isEmpty);
  });

  test('MPT preflight detects non-transferable destination not issuer', () {
    final r = EscrowPreflight.checkMpt(
      tokenCanEscrow: true,
      tokenCanTransfer: false,
      destinationIsIssuerWhenNoTransfer: false,
      sourceHoldsToken: true,
      destinationCanReceive: true,
      sourceLocked: false,
      tokenLockedGlobally: false,
      sourceHasSufficientSpendable: true,
    );
    expect(r.ok, isFalse);
    expect(r.issues, contains('MPToken not transferable and destination is not issuer.'));
  });
}