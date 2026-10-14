import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ad_model.dart';
import '../models/payment_transaction_model.dart';
import '../models/plan_model.dart';
import 'ad_service.dart';

abstract class IPaymentGateway {
  Future<PaymentTransactionModel> createPixCharge({
    required AdModel ad,
    required PlanModel plan,
    required String userEmail,
  });

  Future<PaymentStatus> checkPaymentStatus(String transactionId);
}

/// Serviço de Pagamento Integrado com a API BotaPix
/// Cria cobranças Pix reais e faz verificação em tempo real para liberação automática.
class PaymentService implements IPaymentGateway {
  static final PaymentService instance = PaymentService._internal();
  PaymentService._internal();

  /// Credenciais da API BotaPix
  static const String botaPixApiKey =
      'btpx_5a17bdc85093c45ad64c995b8f3b4800969d1f36abc3eb9a3b7bb490';
  static const String botaPixBaseUrl = 'https://botapix.com/api/v1';

  /// Chave Pix Master padrão de recebimento
  static const String masterPixKey = 'devalefdias44@gmail.com';

  static bool get isConfigured => botaPixApiKey.isNotEmpty;

  @override
  Future<PaymentTransactionModel> createPixCharge({
    required AdModel ad,
    required PlanModel plan,
    required String userEmail,
  }) async {
    final amountInCents = (plan.price * 100).round();
    final externalRef = 'zuvex_ad_${ad.id}_${DateTime.now().millisecondsSinceEpoch}';

    String? botaPixId;
    String? paymentUrl;
    String pixCopiaECola = '';
    String pixQrCode = '';

    // 1. Tenta criar a cobrança real na API do BotaPix
    try {
      final response = await http
          .post(
            Uri.parse('$botaPixBaseUrl/charges'),
            headers: {
              'Authorization': 'Bearer $botaPixApiKey',
              'Content-Type': 'application/json',
              'Idempotency-Key': externalRef,
            },
            body: jsonEncode({
              'amount': amountInCents,
              'external_reference': externalRef,
              'description': 'ZUVEX - ${plan.name} (${ad.title})',
              'expiration': 3600, // 1 hora de validade
              'customer': {
                'name': ad.userName.isNotEmpty ? ad.userName : 'Cliente ZUVEX',
                'email': userEmail.isNotEmpty ? userEmail : masterPixKey,
              },
              'metadata': {
                'ad_id': ad.id,
                'plan_id': plan.id,
                'user_id': ad.userId,
                'ad_title': ad.title,
              },
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('💳 [BotaPix] createCharge status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        botaPixId = data['id']?.toString() ?? data['reference']?.toString();
        paymentUrl = data['payment_url'] as String?;

        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          pixCopiaECola = paymentUrl;
          pixQrCode =
              'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data=${Uri.encodeComponent(paymentUrl)}';
          debugPrint('✅ [BotaPix] Cobrança criada! URL: $paymentUrl | ID: $botaPixId');
        }
      } else {
        debugPrint('⚠️ [BotaPix] Resposta API: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ [BotaPix] Falha ao comunicar com API: $e');
    }

    // 2. Se a chamada à API não retornou URL (ex: offline), gera fallback padrão
    if (pixCopiaECola.isEmpty) {
      final fallbackPix =
          '00020126580014br.gov.bcb.pix0136devalefdias44@gmail.com'
          '520400005303986540${plan.price.toStringAsFixed(2)}5802BR'
          '5925ALEF DIAS ZUVEX6009PROMISSAO'
          '62070503***6304${Random().nextInt(9999).toString().padLeft(4, '0')}';
      pixCopiaECola = fallbackPix;
      pixQrCode =
          'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data=${Uri.encodeComponent(fallbackPix)}';
    }

    final txId = botaPixId ?? 'tx_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    final transaction = PaymentTransactionModel(
      id: txId,
      adId: ad.id,
      adTitle: ad.title,
      userId: ad.userId,
      planId: plan.id,
      planName: plan.name,
      amount: plan.price,
      status: PaymentStatus.pending,
      pixQrCode: pixQrCode,
      pixCopiaECola: pixCopiaECola,
      provider: 'botapix',
      externalReference: externalRef,
      paymentUrl: paymentUrl,
      botaPixChargeId: botaPixId,
      createdAt: DateTime.now(),
    );

    // Salva a transação para registro
    try {
      await AdService.createTransaction(transaction);
    } catch (_) {}

    return transaction;
  }

  /// Consulta o status real da cobrança na API BotaPix
  @override
  Future<PaymentStatus> checkPaymentStatus(String chargeIdOrRef) async {
    if (chargeIdOrRef.isEmpty || chargeIdOrRef.startsWith('tx_')) {
      return PaymentStatus.pending;
    }

    try {
      final response = await http
          .get(
            Uri.parse('$botaPixBaseUrl/charges/$chargeIdOrRef'),
            headers: {
              'Authorization': 'Bearer $botaPixApiKey',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        final status = (data['status'] as String?)?.toLowerCase();

        debugPrint('🔍 [BotaPix] Consulta status de $chargeIdOrRef: $status');

        if (status == 'paid') {
          return PaymentStatus.confirmed;
        } else if (status == 'expired' || status == 'cancelled') {
          return PaymentStatus.expired;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [BotaPix] Erro ao consultar cobrança $chargeIdOrRef: $e');
    }

    return PaymentStatus.pending;
  }

  /// Ativação do anúncio quando o pagamento for confirmado
  Future<bool> confirmPaymentAndActivate({
    required String transactionId,
    required String adId,
    required int durationDays,
  }) async {
    try {
      await AdService.confirmPaymentAndActivateAd(
        transactionId: transactionId,
        adId: adId,
        durationDays: durationDays,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Método para ambiente de homologação/teste assistido
  Future<bool> simulatePaymentConfirmation({
    required String transactionId,
    required String adId,
    required int durationDays,
  }) => confirmPaymentAndActivate(
    transactionId: transactionId,
    adId: adId,
    durationDays: durationDays,
  );
}
