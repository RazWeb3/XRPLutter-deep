// -------------------------------------------------------
// 目的・役割: TokenEscrow（XLS-85）仕様の事前検証ロジック（純粋関数）を提供する。
// 作成日: 2025/11/17
//
// 更新履歴:
// -------------------------------------------------------

class EscrowPreflightResult {
  EscrowPreflightResult(this.ok, this.issues);
  final bool ok;
  final List<String> issues;
}

class EscrowPreflight {
  static EscrowPreflightResult checkIou({
    required bool issuerAllowsTrustLineLocking,
    required bool sourceHasTrustline,
    required bool destinationTrustlineCreatable,
    required bool issuerRequiresAuth,
    required bool sourceAuthorized,
    required bool destinationAuthorized,
    required bool sourceFrozen,
    required bool destinationFrozen,
    required bool sourceHasSufficientSpendable,
  }) {
    final issues = <String>[];
    if (!issuerAllowsTrustLineLocking) {
      issues.add('Issuer disallows trust line locking (IOU escrow not permitted).');
    }
    if (!sourceHasTrustline) {
      issues.add('Source lacks trustline with issuer.');
    }
    if (!destinationTrustlineCreatable) {
      issues.add('Destination trustline cannot be created.');
    }
    if (issuerRequiresAuth && !sourceAuthorized) {
      issues.add('Source not authorized to hold token.');
    }
    if (issuerRequiresAuth && !destinationAuthorized) {
      issues.add('Destination not authorized to hold token.');
    }
    if (sourceFrozen) {
      issues.add('Source account/token is frozen.');
    }
    if (destinationFrozen) {
      issues.add('Destination account/token is frozen.');
    }
    if (!sourceHasSufficientSpendable) {
      issues.add('Insufficient spendable balance.');
    }
    return EscrowPreflightResult(issues.isEmpty, issues);
  }

  static EscrowPreflightResult checkMpt({
    required bool tokenCanEscrow,
    required bool tokenCanTransfer,
    required bool destinationIsIssuerWhenNoTransfer,
    required bool sourceHoldsToken,
    required bool destinationCanReceive,
    required bool sourceLocked,
    required bool tokenLockedGlobally,
    required bool sourceHasSufficientSpendable,
  }) {
    final issues = <String>[];
    if (!tokenCanEscrow) {
      issues.add('MPToken issuance lacks lsfMPTCanEscrow.');
    }
    if (!tokenCanTransfer && !destinationIsIssuerWhenNoTransfer) {
      issues.add('MPToken not transferable and destination is not issuer.');
    }
    if (!sourceHoldsToken) {
      issues.add('Source does not hold MPT.');
    }
    if (!destinationCanReceive) {
      issues.add('Destination cannot receive MPT.');
    }
    if (sourceLocked) {
      issues.add('Source token is locked.');
    }
    if (tokenLockedGlobally) {
      issues.add('Token issuance is globally locked.');
    }
    if (!sourceHasSufficientSpendable) {
      issues.add('Insufficient spendable MPT balance.');
    }
    return EscrowPreflightResult(issues.isEmpty, issues);
  }
}