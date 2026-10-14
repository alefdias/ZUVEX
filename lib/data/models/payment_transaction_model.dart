import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  pending('Aguardando pagamento'),
  confirmed('Confirmado'),
  expired('Expirado'),
  cancelled('Cancelado'),
  refunded('Reembolsado');

  final String label;
  const PaymentStatus(this.label);

  static PaymentStatus fromString(String? val) {
    switch (val) {
      case 'confirmed':
      case 'aprovado':
        return PaymentStatus.confirmed;
      case 'expired':
      case 'expirado':
        return PaymentStatus.expired;
      case 'cancelled':
      case 'cancelado':
        return PaymentStatus.cancelled;
      case 'refunded':
      case 'reembolsado':
        return PaymentStatus.refunded;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  String toDbValue() {
    switch (this) {
      case PaymentStatus.confirmed:
        return 'confirmed';
      case PaymentStatus.expired:
        return 'expired';
      case PaymentStatus.cancelled:
        return 'cancelled';
      case PaymentStatus.refunded:
        return 'refunded';
      case PaymentStatus.pending:
        return 'pending';
    }
  }
}

class PaymentTransactionModel {
  final String id;
  final String adId;
  final String adTitle;
  final String userId;
  final String planId;
  final String planName;
  final double amount;
  final PaymentStatus status;
  final String pixQrCode;
  final String pixCopiaECola;
  final String provider;
  final String? externalReference;
  final String? paymentUrl;
  final String? botaPixChargeId;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  const PaymentTransactionModel({
    required this.id,
    required this.adId,
    required this.adTitle,
    required this.userId,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.status,
    required this.pixQrCode,
    required this.pixCopiaECola,
    this.provider = 'botapix',
    this.externalReference,
    this.paymentUrl,
    this.botaPixChargeId,
    required this.createdAt,
    this.confirmedAt,
  });

  String get formattedAmount => 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adId': adId,
      'adTitle': adTitle,
      'userId': userId,
      'planId': planId,
      'planName': planName,
      'amount': amount,
      'status': status.toDbValue(),
      'pixQrCode': pixQrCode,
      'pixCopiaECola': pixCopiaECola,
      'provider': provider,
      'externalReference': externalReference,
      'paymentUrl': paymentUrl,
      'botaPixChargeId': botaPixChargeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
    };
  }

  factory PaymentTransactionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return PaymentTransactionModel(
      id: id ?? map['id'] ?? '',
      adId: map['adId'] ?? '',
      adTitle: map['adTitle'] ?? 'Publicação de Anúncio',
      userId: map['userId'] ?? '',
      planId: map['planId'] ?? 'basic',
      planName: map['planName'] ?? 'Plano Básico',
      amount: (map['amount'] as num?)?.toDouble() ?? 5.0,
      status: PaymentStatus.fromString(map['status']),
      pixQrCode: map['pixQrCode'] ?? '',
      pixCopiaECola: map['pixCopiaECola'] ?? '',
      provider: map['provider'] ?? 'botapix',
      externalReference: map['externalReference'],
      paymentUrl: map['paymentUrl'],
      botaPixChargeId: map['botaPixChargeId'],
      createdAt: parseDate(map['createdAt']),
      confirmedAt: map['confirmedAt'] != null ? parseDate(map['confirmedAt']) : null,
    );
  }
}
