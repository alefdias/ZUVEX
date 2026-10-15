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

/// Serviço de Pagamento Integrado com a API BotaPix e Gerador Oficial BACEN
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

  /// User-Agent padrão para evitar bloqueio do Cloudflare
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static bool get isConfigured => botaPixApiKey.isNotEmpty;

  /// Calcula o checksum CRC16-CCITT (0xFFFF) obrigatório pelo Banco Central do Brasil para Pix
  static String calculateCrc16(String payload) {
    int poly = 0x1021;
    int crc = 0xFFFF;
    final bytes = utf8.encode(payload);
    for (final byte in bytes) {
      crc ^= (byte << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ poly) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  /// Gera código Pix Copia e Cola Oficial (Padrão EMV BRCode do Banco Central do Brasil)
  /// Reconhecido por todos os bancos (Nubank, Itaú, Bradesco, Inter, Caixa, BB, Santander, etc.)
  static String generateBacenPix({
    required String pixKey,
    required String merchantName,
    required String merchantCity,
    required double amount,
    String txid = '***',
  }) {
    final cleanName = merchantName.length > 25 ? merchantName.substring(0, 25) : merchantName;
    final cleanCity = merchantCity.length > 15 ? merchantCity.substring(0, 15) : merchantCity;
    final amountStr = amount.toStringAsFixed(2);
    final cleanTxid = (txid.isEmpty || txid == '***') ? '***' : txid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final finalTxid = cleanTxid.length > 25 ? cleanTxid.substring(0, 25) : cleanTxid;

    // GUI oficial do Banco Central: BR.GOV.BCB.PIX em maiúsculo
    final maiGui = '0014BR.GOV.BCB.PIX';
    final maiKey = '01${pixKey.length.toString().padLeft(2, '0')}$pixKey';
    final maiContent = '$maiGui$maiKey';
    final mai = '26${maiContent.length.toString().padLeft(2, '0')}$maiContent';

    // 010212 = Ponto de Iniciação: QR Code Estático com valor pré-definido
    final poi = '010212';
    final mcc = '52040000';
    final curr = '5303986'; // Real Brasileiro
    final amt = '54${amountStr.length.toString().padLeft(2, '0')}$amountStr';
    final ctry = '5802BR';
    final nm = '59${cleanName.length.toString().padLeft(2, '0')}$cleanName';
    final ct = '60${cleanCity.length.toString().padLeft(2, '0')}$cleanCity';
    final ad = '62${(finalTxid.length + 4).toString().padLeft(2, '0')}05${finalTxid.length.toString().padLeft(2, '0')}$finalTxid';

    final raw = '000201$poi$mai$mcc$curr$amt$ctry$nm$ct$ad' '6304';
    final crc = calculateCrc16(raw);
    return '$raw$crc';
  }

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

    // 1. Tenta criar a cobrança real na API do BotaPix (usando User-Agent para contornar Cloudflare)
    try {
      final response = await http
          .post(
            Uri.parse('$botaPixBaseUrl/charges'),
            headers: {
              'Authorization': 'Bearer $botaPixApiKey',
              'Content-Type': 'application/json',
              'User-Agent': userAgent,
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
          debugPrint('🌐 [BotaPix] URL gerada: $paymentUrl');

          // Busca a página de pagamento para extrair o código oficial do Banco Central
          try {
            final pageRes = await http.get(
              Uri.parse(paymentUrl),
              headers: {
                'User-Agent': userAgent,
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              },
            ).timeout(const Duration(seconds: 8));

            if (pageRes.statusCode == 200) {
              // Desescapa barras e aspas da página Inertia.js
              final normalized = pageRes.body
                  .replaceAll(r'\/', '/')
                  .replaceAll('&quot;', '"');

              // 1. Busca código Pix Copia e Cola Oficial
              final pixMatch = RegExp(r'(000201[A-Za-z0-9\.\_\-\/\*]+6304[A-Fa-f0-9]{4})')
                  .firstMatch(normalized);
              if (pixMatch != null) {
                pixCopiaECola = pixMatch.group(1)!;
                debugPrint('✅ [BotaPix] Código Pix Copia e Cola Oficial extraído com sucesso!');
              }

              // 2. Busca imagem QR Code gerada pelo BotaPix / Efí Bank em base64
              final qrMatch = RegExp(r'(data:image\/png;base64,[A-Za-z0-9+/=]+)')
                  .firstMatch(normalized);
              if (qrMatch != null) {
                pixQrCode = qrMatch.group(1)!;
                debugPrint('✅ [BotaPix] Imagem QR Code Base64 extraída com sucesso!');
              }
            }
          } catch (e) {
            debugPrint('⚠️ [BotaPix] Não foi possível extrair dados da página de pagamento: $e');
          }
        }
      } else {
        debugPrint('⚠️ [BotaPix] Resposta API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ [BotaPix] Falha ao comunicar com API: $e');
    }

    // 2. Se a API BotaPix não retornou o código EMV válido, gera o Pix BACEN Oficial real com CRC16
    if (pixCopiaECola.isEmpty || !pixCopiaECola.startsWith('000201')) {
      debugPrint('ℹ️ [Pix] Gerando código Pix Oficial BACEN com CRC16 válido para $masterPixKey...');
      pixCopiaECola = generateBacenPix(
        pixKey: masterPixKey,
        merchantName: 'ALEF DIAS ZUVEX',
        merchantCity: 'PROMISSAO',
        amount: plan.price,
        txid: botaPixId != null ? 'ZUV${botaPixId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}' : '***',
      );
    }

    // 3. Se a imagem do QR Code em base64 não foi obtida, gera a imagem a partir do Copia e Cola
    if (pixQrCode.isEmpty) {
      pixQrCode =
          'https://api.qrserver.com/v1/create-qr-code/?size=300x300&margin=10&data=${Uri.encodeComponent(pixCopiaECola)}';
    }

    debugPrint('📱 [Pix] Payload pronto para o banco: ${pixCopiaECola.substring(0, min(50, pixCopiaECola.length))}...');

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
              'User-Agent': userAgent,
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
