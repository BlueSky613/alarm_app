import 'package:flutter/material.dart';
import 'package:dawn_weaver/l10n/app_localizations.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/wallet_balance_service.dart';

const Color _kGatePrimary = Color(0xFF0EF196);

/// Loads SKR/SOL from chain, shows a modal with balances, and returns whether
/// the user may proceed (SKR ≥ [WalletBalanceService.minimumSkrToSaveAlarm]
/// and user tapped confirm when allowed).
Future<bool> ensureWalletAllowsAlarmSave(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final isSpanish = l10n.isSpanish;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  final userProfile = await StorageService.getUserProfile();
  final wallet = userProfile?.solanaAddress?.trim() ?? '';

  if (wallet.isEmpty) {
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'Conecta una billetera Solana en el perfil para guardar alarmas.'
                : 'Connect a Solana wallet in your profile to save alarms.',
          ),
        ),
      );
    }
    return false;
  }

  double skr;
  double sol;
  try {
    final balances = await WalletBalanceService.fetchSkrAndSol(wallet);
    skr = balances.skr;
    sol = balances.sol;
  } catch (e) {
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'No se pudo leer el saldo: $e'
                : 'Could not read wallet balance: $e',
          ),
        ),
      );
    }
    return false;
  }

  if (context.mounted) Navigator.of(context).pop();
  if (!context.mounted) return false;

  // If balance is sufficient, proceed silently without showing a modal.
  if (skr >= WalletBalanceService.minimumSkrToSaveAlarm) {
    return true;
  }

  // Insufficient SKR — show warning modal.
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF101010),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _kGatePrimary.withValues(alpha: 0.35)),
        ),
        title: Text(
          isSpanish ? 'Saldo insuficiente' : 'Insufficient Balance',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BalanceRow(label: 'SKR', value: skr.toStringAsFixed(4)),
            const SizedBox(height: 12),
            _BalanceRow(
              label: isSpanish ? 'Solana (SOL)' : 'Solana (SOL)',
              value: sol.toStringAsFixed(6),
            ),
            const SizedBox(height: 16),
            Text(
              isSpanish
                  ? 'Necesitas al menos ${WalletBalanceService.minimumSkrToSaveAlarm.toInt()} SKR para guardar una alarma.'
                  : 'You need at least ${WalletBalanceService.minimumSkrToSaveAlarm.toInt()} SKR to save an alarm.',
              style: TextStyle(
                color: Colors.redAccent.shade200,
                fontSize: 16,
                height: 1.35,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              isSpanish ? 'Entendido' : 'OK',
              style: const TextStyle(
                color: _kGatePrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
  return false;
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 15,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
