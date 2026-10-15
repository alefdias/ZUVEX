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

  /// URL do Backend Seguro ZUVEX (Node.js / Cloud Functions)
  /// Caso configurado, todas as chamadas de pagamento e segredos ficam isolados no servidor.
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  /// Credenciais da API BotaPix (injetáveis via --dart-define para segurança)
  static const String botaPixApiKey = String.fromEnvironment(
    'BOTAPIX_API_KEY',
    defaultValue: 'btpx_5a17bdc85093c45ad64c995b8f3b4800969d1f36abc3eb9a3b7bb490',
  );
  static const String botaPixBaseUrl = 'https://botapix.com/api/v1';

  /// Chave Pix Master padrão de recebimento
  static const String masterPixKey = 'devalefdias44@gmail.com';

  /// User-Agent padrão para evitar bloqueio do Cloudflare
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static bool get isConfigured => backendUrl.isNotEmpty || botaPixApiKey.isNotEmpty;

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
    // Para Pix estático manual, o padrão oficial BACEN exige txid literal *** para garantir aceitação universal em todos os bancos
    const finalTxid = '***';

    // GUI oficial do Banco Central: BR.GOV.BCB.PIX em maiúsculo
    final maiGui = '0014BR.GOV.BCB.PIX';
    final maiKey = '01${pixKey.length.toString().padLeft(2, '0')}$pixKey';
    final maiContent = '$maiGui$maiKey';
    final mai = '26${maiContent.length.toString().padLeft(2, '0')}$maiContent';

    // 010211 = Ponto de Iniciação: QR Code Estático (MANDATÓRIO pelo BACEN para chaves Pix diretas)
    // Se usar 010212 aqui, os bancos tentam buscar cobrança dinâmica via URL e dão erro "Pix não reconhecido"
    final poi = '010211';
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
    // Garante que o valor enviado à BotaPix seja de pelo menos 100 centavos (R$ 1,00 - mínimo da API)
    final amountInCents = max(100, (plan.price * 100).round());
    final externalRef = 'zuvex_ad_${ad.id}_${DateTime.now().millisecondsSinceEpoch}';

    final clientName = ad.userName.trim().isNotEmpty ? ad.userName.trim() : 'Usuário ZUVEX';
    final clientPhone = ad.contactPhone.trim().isNotEmpty ? ad.contactPhone.trim() : '';
    final clientEmail = userEmail.trim().isNotEmpty
        ? userEmail.trim()
        : (ad.userEmail.trim().isNotEmpty ? ad.userEmail.trim() : masterPixKey);

    // Formata descrição rica para identificação visual imediata no dashboard da BotaPix
    final phoneInfo = clientPhone.isNotEmpty ? ' | Tel: $clientPhone' : '';
    final desc = 'ZUVEX | $clientName$phoneInfo | $clientEmail - ${plan.name} (${ad.title})';
    final cleanDesc = desc.length > 250 ? desc.substring(0, 250) : desc;

    String? botaPixId;
    String? paymentUrl;
    String pixCopiaECola = '';
    String pixQrCode = '';

    // 0. Se houver um backend seguro configurado, delega a geração para o servidor
    if (backendUrl.isNotEmpty) {
      try {
        final resp = await http.post(
          Uri.parse('$backendUrl/api/create-pix'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'adId': ad.id,
            'adTitle': ad.title,
            'planId': plan.id,
            'planName': plan.name,
            'amount': plan.price,
            'userEmail': clientEmail,
            'userName': clientName,
            'contactPhone': clientPhone,
            'durationDays': plan.durationDays,
          }),
        ).timeout(const Duration(seconds: 10));

        if (resp.statusCode == 200) {
          final resData = jsonDecode(resp.body);
          final txId = resData['transactionId'] ?? externalRef;
          final tx = PaymentTransactionModel(
            id: txId,
            adId: ad.id,
            adTitle: ad.title,
            userId: ad.userId,
            userEmail: clientEmail,
            planId: plan.id,
            planName: plan.name,
            amount: plan.price,
            status: PaymentStatus.pending,
            pixQrCode: resData['qrCodeUrl'] ?? '',
            pixCopiaECola: resData['copyPaste'] ?? '',
            externalReference: externalRef,
            botaPixChargeId: txId,
            createdAt: DateTime.now(),
          );
          return tx;
        }
      } catch (e) {
        debugPrint('⚠️ [PaymentService] Backend seguro indisponível, usando fallback: $e');
      }
    }

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
              'description': cleanDesc,
              'expiration': 3600, // 1 hora de validade
              'customer': {
                'name': clientName,
                'email': clientEmail,
                if (clientPhone.isNotEmpty) 'phone': clientPhone,
              },
              'metadata': {
                'ad_id': ad.id,
                'ad_title': ad.title,
                'plan_id': plan.id,
                'plan_name': plan.name,
                'user_id': ad.userId,
                'user_name': clientName,
                'user_email': clientEmail,
                'user_phone': clientPhone,
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
              // 1. Método Principal: Extração precisa via JSON da prop transaction do Inertia.js
              try {
                final dataPageMatch = RegExp(r'data-page="([^"]+)"').firstMatch(pageRes.body);
                if (dataPageMatch != null) {
                  final rawData = dataPageMatch.group(1)!
                      .replaceAll('&quot;', '"')
                      .replaceAll('&amp;', '&')
                      .replaceAll('&lt;', '<')
                      .replaceAll('&gt;', '>');
                  final parsed = jsonDecode(rawData);
                  final tx = parsed['props']?['transaction'];
                  if (tx != null) {
                    final rawPix = tx['pix_copia_cola']?.toString() ?? '';
                    final rawQr = tx['qr_code']?.toString() ?? '';
                    if (rawPix.startsWith('000201')) {
                      pixCopiaECola = rawPix.trim();
                      debugPrint('✅ [BotaPix] Código Pix Oficial extraído via data-page JSON!');
                    }
                    if (rawQr.isNotEmpty) {
                      pixQrCode = rawQr.trim();
                      debugPrint('✅ [BotaPix] QR Code Base64 extraído via data-page JSON!');
                    }
                  }
                }
              } catch (e) {
                debugPrint('⚠️ [BotaPix] Falha no parse JSON de data-page: $e');
              }

              // 2. Fallback via regex caso o parse do JSON falhe
              if (pixCopiaECola.isEmpty) {
                final normalized = pageRes.body
                    .replaceAll(r'\/', '/')
                    .replaceAll('&quot;', '"');

                final pixMatch = RegExp(r'(000201[A-Za-z0-9\.\_\-\/\*]+6304[A-Fa-f0-9]{4})')
                    .firstMatch(normalized);
                if (pixMatch != null) {
                  pixCopiaECola = pixMatch.group(1)!.trim();
                  debugPrint('✅ [BotaPix] Código Pix Copia e Cola Oficial extraído via Regex!');
                }

                final qrMatch = RegExp(r'(data:image\/png;base64,[A-Za-z0-9+/=]+)')
                    .firstMatch(normalized);
                if (qrMatch != null) {
                  pixQrCode = qrMatch.group(1)!.trim();
                  debugPrint('✅ [BotaPix] Imagem QR Code Base64 extraída via Regex!');
                }
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
        txid: '***',
      ).trim();
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

    // Se houver backend seguro configurado, consulta diretamente por ele
    if (backendUrl.isNotEmpty) {
      try {
        final resp = await http.get(
          Uri.parse('$backendUrl/api/status/$chargeIdOrRef'),
        ).timeout(const Duration(seconds: 8));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final status = (data['status'] as String?)?.toLowerCase();
          if (status == 'confirmed' || status == 'paid') {
            return PaymentStatus.confirmed;
          } else if (status == 'expired' || status == 'cancelled') {
            return PaymentStatus.expired;
          }
        }
      } catch (_) {}
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
