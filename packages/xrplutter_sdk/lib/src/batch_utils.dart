// -------------------------------------------------------
// 目的・役割: Batchモードに基づく適用結果の決定ロジック（純粋関数）。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

import 'batch_service.dart';

class BatchUtils {
  /// 成功/失敗の配列に対して、指定モードでどのトランザクションが適用されるかを返す
  static List<bool> decideAppliedIndices({
    required int modeFlags,
    required List<bool> successes,
  }) {
    if (successes.length < 2 || successes.length > 8) {
      throw ArgumentError('successesは2〜8件で指定してください');
    }
    final applied = List<bool>.filled(successes.length, false);
    if (modeFlags == BatchService.tfAllOrNothing) {
      final all = successes.every((s) => s);
      if (all) {
        for (var i = 0; i < applied.length; i++) {
          applied[i] = true;
        }
      }
      return applied;
    }
    if (modeFlags == BatchService.tfOnlyOne) {
      final idx = successes.indexWhere((s) => s);
      if (idx >= 0) applied[idx] = true;
      return applied;
    }
    if (modeFlags == BatchService.tfUntilFailure) {
      for (var i = 0; i < successes.length; i++) {
        if (successes[i]) {
          applied[i] = true;
        } else {
          break;
        }
      }
      return applied;
    }
    if (modeFlags == BatchService.tfIndependent) {
      for (var i = 0; i < successes.length; i++) {
        applied[i] = successes[i];
      }
      return applied;
    }
    return applied;
  }
}