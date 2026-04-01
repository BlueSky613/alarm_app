import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

/// Fetches on-chain SKR (token) and native SOL balances for a wallet address.
/// Uses mainnet RPC (SKR mint is on mainnet).
class WalletBalanceService {
  WalletBalanceService._();

  static const String skrMint = 'SKRbvo6Gf7GondiT3BbTfuRDPqLWei4j2Qy2NPGZhW3';

  static final SolanaClient _client = SolanaClient(
    rpcUrl: Uri.parse('https://api.mainnet-beta.solana.com'),
    websocketUrl: Uri.parse('wss://api.mainnet-beta.solana.com'),
  );

  /// Minimum SKR required to create or update an alarm.
  static const double minimumSkrToSaveAlarm = 0;

  static Future<double> fetchSkrBalance(String address) async {
    final result = await _client.rpcClient.getTokenAccountsByOwner(
      address,
      const TokenAccountsFilter.byMint(skrMint),
      encoding: Encoding.jsonParsed,
    );
    double total = 0;
    if (result.value.isEmpty) return 0;
    for (final acc in result.value) {
      final data = acc.account.data;
      if (data is ParsedAccountData) {
        final info = data.toJson()['parsed']['info'] as Map<String, dynamic>;
        final tokenAmount = info['tokenAmount'] as Map<String, dynamic>;
        total += double.parse(tokenAmount['uiAmountString'] as String);
      }
    }
    return total;
  }

  static Future<double> fetchSolBalance(String address) async {
    final res = await _client.rpcClient.getBalance(address);
    return res.value / 1000000000.0;
  }

  static Future<({double skr, double sol})> fetchSkrAndSol(
    String address,
  ) async {
    final skr = await fetchSkrBalance(address);
    final sol = await fetchSolBalance(address);
    return (skr: skr, sol: sol);
  }
}
