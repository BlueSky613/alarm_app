import 'dart:typed_data';

import 'package:dawn_weaver/services/wallet_balance_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart' show Encoding;
import 'package:solana/encoder.dart' show Instruction, Message, SignedTx;
import 'package:solana/solana.dart';
import 'package:solana_common/models.dart';

class PremiumPaymentException implements Exception {
  PremiumPaymentException(this.message);
  final String message;

  @override
  String toString() => message;
}

const int premiumPriceSkr = 199;

/// Wraps a [SignedTx] (with placeholder sigs) so the wallet adapter can
/// encode it via [TransactionSerializableMixin].
class UnsignedPremiumPaymentTx with TransactionSerializableMixin {
  UnsignedPremiumPaymentTx(this._inner);
  final SignedTx _inner;

  @override
  Iterable<int> serialize([TransactionSerializableConfig? config]) =>
      _inner.toByteArray().toList();

  @override
  Iterable<int> serializeMessage() =>
      _inner.compiledMessage.toByteArray().toList();
}

class PremiumPaymentService {
  PremiumPaymentService._();

  static String? clientTreasuryAddress() {
    final v = dotenv.env['client_wallet_address']?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// Builds an SPL transfer of [premiumPriceSkr] SKR from
  /// [senderWalletBase58] to `client_wallet_address` (.env treasury).
  /// Creates the treasury ATA if it doesn't exist yet.
  static Future<SignedTx> buildPremiumSkrPaymentTx({
    required SolanaClient client,
    required String senderWalletBase58,
  }) async {
    final treasury = clientTreasuryAddress();
    if (treasury == null) {
      throw PremiumPaymentException(
        'Missing client_wallet_address in .env (treasury wallet).',
      );
    }

    final sender = Ed25519HDPublicKey.fromBase58(senderWalletBase58);
    final recipient = Ed25519HDPublicKey.fromBase58(treasury);
    final mint = Ed25519HDPublicKey.fromBase58(WalletBalanceService.skrMint);

    final mintInfo = await client.getMint(address: mint);
    final amount =
        (BigInt.from(premiumPriceSkr) * BigInt.from(10).pow(mintInfo.decimals))
            .toInt();

    final senderAta = await findAssociatedTokenAddress(
      owner: sender,
      mint: mint,
    );
    final recipientAta = await findAssociatedTokenAddress(
      owner: recipient,
      mint: mint,
    );

    final senderAcc = await client.rpcClient.getAccountInfo(
      senderAta.toBase58(),
      encoding: Encoding.base64,
    );
    if (senderAcc.value == null) {
      throw PremiumPaymentException(
        'No SKR token account found. You need at least $premiumPriceSkr SKR.',
      );
    }

    final recipAcc = await client.rpcClient.getAccountInfo(
      recipientAta.toBase58(),
      encoding: Encoding.base64,
    );

    final bhRes = await client.rpcClient.getLatestBlockhash(
      commitment: Commitment.confirmed,
    );

    final instructions = <Instruction>[];

    if (recipAcc.value == null) {
      instructions.add(
        AssociatedTokenAccountInstruction.createAccount(
          funder: sender,
          address: recipientAta,
          owner: recipient,
          mint: mint,
        ),
      );
    }

    instructions.add(
      TokenInstruction.transferChecked(
        source: senderAta,
        destination: recipientAta,
        mint: mint,
        owner: sender,
        amount: amount,
        decimals: mintInfo.decimals,
      ),
    );

    instructions.add(
      MemoInstruction(signers: [sender], memo: 'DAWN_PREMIUM_V1'),
    );

    final message = Message(instructions: instructions);
    final compiled = message.compile(
      recentBlockhash: bhRes.value.blockhash,
      feePayer: sender,
    );

    // Placeholder zero-signatures — the wallet adapter will replace them.
    final n = compiled.requiredSignatureCount;
    final keys = compiled.accountKeys;
    final sigs = List.generate(
      n,
      (i) => Signature(Uint8List(64), publicKey: keys[i]),
    );

    return SignedTx(signatures: sigs, compiledMessage: compiled);
  }
}
