import 'dart:convert';

import 'package:dawn_weaver/utils/api_base_url.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Syncs Pro/premium status with the Laravel `wallet_users` table.
Future<bool> syncWalletPremium({
  required String walletAddress,
  required bool premium,
}) async {
  final baseUrl = resolveApiBaseUrl(dotenv.env['base_url']);
  if (baseUrl.isEmpty) return false;

  final response = await http.post(
    Uri.parse('$baseUrl/api/v1/wallet-users/premium'),
    headers: const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'wallet_address': walletAddress,
      'premium': premium,
    }),
  );

  return response.statusCode >= 200 && response.statusCode < 300;
}

/// Updates wallet on the admin API using the current [apiToken]; server returns a new token.
Future<({String? token, String? message, int statusCode})> changeWalletWithApiToken({
  required String apiToken,
  required String newWalletAddress,
  String? cluster,
}) async {
  final baseUrl = resolveApiBaseUrl(dotenv.env['base_url']);
  if (baseUrl.isEmpty) {
    return (token: null, message: 'Missing API base URL.', statusCode: 0);
  }

  final body = <String, dynamic>{
    'token': apiToken,
    'wallet_address': newWalletAddress,
  };
  if (cluster != null && cluster.isNotEmpty) {
    body['cluster'] = cluster;
  }

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/wallet-users/change-wallet'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {}

    final msg = decoded?['message'] as String?;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final newToken = decoded?['token'] as String?;
      if (newToken == null || newToken.isEmpty) {
        return (
          token: null,
          message: msg ?? 'Server did not return a token.',
          statusCode: response.statusCode,
        );
      }
      return (token: newToken, message: msg, statusCode: response.statusCode);
    }

    return (
      token: null,
      message: msg ?? 'Request failed (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  } catch (e) {
    return (token: null, message: e.toString(), statusCode: 0);
  }
}
