import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class NETSService {
  final String apiKey = 'Q1kMnniECOCpsoxTzYPv';
  final String projectId = '9878d07d-1981-4e86-b36d-2deafd291c65';

  // Generates a NETS QR payment request
  Future<Map<String, dynamic>> requestQR(double amount) async {
    try {
      final url = Uri.parse(
        'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets-qr/request',
      );

      final response = await post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
          'project-id': projectId,
        },
        body: jsonEncode({
          'txn_id': 'sandbox_nets|m|8ff8e5b6-d43e-4786-8ac5-7accf8c5bd9b',
          'amt_in_dollars': amount,
          'notify_mobile': 0,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        'qrCode': data['result']['data']['qr_code'],
        'txnRef': data['result']['data']['txn_retrieval_ref'],
      };
    } catch (e) {
      debugPrint('requestQR error: $e');
      return {};
    }
  }

  // SSE stream for real-time payment updates
  Stream<String> webhookStream(String txnRef) async* {
    final client = Client();

    final url = Uri.parse(
      'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets/webhook?txn_retrieval_ref=$txnRef',
    );

    final request = Request('GET', url)
      ..headers.addAll({
        'Accept': 'text/event-stream',
        'Connection': 'keep-alive',
        'api-key': apiKey,
        'project-id': projectId,
      });

    final response = await client.send(request);

    if (response.statusCode == 200) {
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        yield chunk;
      }
    }
  }

  // Final payment status check
  Future<Map<String, dynamic>> checkPayment(String txnRef) async {
    try {
      final url = Uri.parse(
        'https://sandbox.nets.openapipaas.com/api/v1/common/payments/nets-qr/query',
      );

      final response = await post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
          'project-id': projectId,
        },
        body: jsonEncode({
          'txn_retrieval_ref': txnRef,
          'frontend_timeout_status': 1,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        "response_code": data['result']['data']['response_code'],
        "message": data['result']['data']['message'],
      };
    } catch (e) {
      debugPrint('checkPayment error: $e');
      return {};
    }
  }
}