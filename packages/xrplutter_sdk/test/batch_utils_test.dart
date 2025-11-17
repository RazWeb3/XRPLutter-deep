// -------------------------------------------------------
// 目的・役割: BatchUtilsの適用結果決定ロジックをテスト。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'package:test/test.dart';
import 'package:xrplutter_sdk/xrplutter.dart';

void main() {
  final successes = [false, true, true];

  test('ALLORNOTHING applies none when any fails', () {
    final applied = BatchUtils.decideAppliedIndices(
      modeFlags: BatchService.tfAllOrNothing,
      successes: successes,
    );
    expect(applied, equals([false, false, false]));
  });

  test('ONLYONE applies first success only', () {
    final applied = BatchUtils.decideAppliedIndices(
      modeFlags: BatchService.tfOnlyOne,
      successes: successes,
    );
    expect(applied, equals([false, true, false]));
  });

  test('UNTILFAILURE applies successes until first failure', () {
    final applied = BatchUtils.decideAppliedIndices(
      modeFlags: BatchService.tfUntilFailure,
      successes: [true, true, false, true],
    );
    expect(applied, equals([true, true, false, false]));
  });

  test('INDEPENDENT applies all successes', () {
    final applied = BatchUtils.decideAppliedIndices(
      modeFlags: BatchService.tfIndependent,
      successes: successes,
    );
    expect(applied, equals([false, true, true]));
  });
}