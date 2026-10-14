import 'package:cloud_firestore/cloud_firestore.dart';

enum AdStatus {
  draft('Rascunho'),
  pendingPayment('Aguardando pagamento'),
  inReview('Em análise'),
  active('Ativo'),
  rejected('Rejeitado'),
  expired('Expirado'),
  sold('Vendido'),
  removed('Removido');

  final String label;
  const AdStatus(this.label);

  static AdStatus fromString(String? val) {
    switch (val) {
      case 'draft':
      case 'rascunho':
        return AdStatus.draft;
      case 'pending_payment':
      case 'aguardando_pagamento':
        return AdStatus.pendingPayment;
      case 'in_review':
      case 'em_analise':
        return AdStatus.inReview;
      case 'active':
      case 'ativo':
        return AdStatus.active;
      case 'rejected':
      case 'rejeitado':
        return AdStatus.rejected;
      case 'expired':
      case 'expirado':
        return AdStatus.expired;
      case 'sold':
      case 'vendido':
        return AdStatus.sold;
      case 'removed':
      case 'removido':
        return AdStatus.removed;
      default:
        return AdStatus.active;
    }
  }

  String toDbValue() {
    switch (this) {
      case AdStatus.draft:
        return 'draft';
      case AdStatus.pendingPayment:
        return 'pending_payment';
      case AdStatus.inReview:
        return 'in_review';
      case AdStatus.active:
        return 'active';
      case AdStatus.rejected:
        return 'rejected';
      case AdStatus.expired:
        return 'expired';
      case AdStatus.sold:
        return 'sold';
      case AdStatus.removed:
        return 'removed';
    }
  }
}

class AdModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final String title;
  final String description;
  final double price;
  final String categoryId;
  final List<String> images;
  final String cityId;
  final String cityName;
  final String district; // Bairro
  final String contactPhone;
  final bool allowWhatsApp;
  final String planId;
  final bool isFeatured;
  final AdStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int viewsCount;
  final Map<String, dynamic> specificFields;
  final String? rejectionReason;
  final bool isPixVerified;

  AdModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.title,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.images,
    required this.cityId,
    required this.cityName,
    required this.district,
    required this.contactPhone,
    this.allowWhatsApp = true,
    required this.planId,
    this.isFeatured = false,
    this.status = AdStatus.pendingPayment,
    required this.createdAt,
    this.expiresAt,
    this.viewsCount = 0,
    this.specificFields = const {},
    this.rejectionReason,
    this.isPixVerified = false,
  });

  String get formattedPrice {
    if (price <= 0) return 'A combinar';
    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get primaryImage {
    if (images.isNotEmpty) return images.first;
    return 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&auto=format&fit=crop&q=80';
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userAvatar': userAvatar,
      'title': title,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'images': images,
      'cityId': cityId,
      'cityName': cityName,
      'district': district,
      'contactPhone': contactPhone,
      'allowWhatsApp': allowWhatsApp,
      'planId': planId,
      'isFeatured': isFeatured,
      'status': status.toDbValue(),
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'viewsCount': viewsCount,
      'specificFields': specificFields,
      'rejectionReason': rejectionReason,
      'isPixVerified': isPixVerified,
    };
  }

  factory AdModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final adStatus = AdStatus.fromString(map['status']);
    return AdModel(
      id: id ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anunciante ZUVEX',
      userEmail: map['userEmail'] ?? '',
      userAvatar: map['userAvatar'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      categoryId: map['categoryId'] ?? 'outros',
      images: List<String>.from(map['images'] ?? []),
      cityId: map['cityId'] ?? 'promissao_sp',
      cityName: map['cityName'] ?? 'Promissão - SP',
      district: map['district'] ?? 'Centro',
      contactPhone: map['contactPhone'] ?? '',
      allowWhatsApp: map['allowWhatsApp'] ?? true,
      planId: map['planId'] ?? 'basic',
      isFeatured: map['isFeatured'] ?? false,
      status: adStatus,
      createdAt: parseDate(map['createdAt']),
      expiresAt: map['expiresAt'] != null ? parseDate(map['expiresAt']) : null,
      viewsCount: (map['viewsCount'] as num?)?.toInt() ?? 0,
      specificFields: Map<String, dynamic>.from(map['specificFields'] ?? {}),
      rejectionReason: map['rejectionReason'],
      isPixVerified: map['isPixVerified'] == true || adStatus == AdStatus.active,
    );
  }

  AdModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? userAvatar,
    String? title,
    String? description,
    double? price,
    String? categoryId,
    List<String>? images,
    String? cityId,
    String? cityName,
    String? district,
    String? contactPhone,
    bool? allowWhatsApp,
    String? planId,
    bool? isFeatured,
    AdStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? viewsCount,
    Map<String, dynamic>? specificFields,
    String? rejectionReason,
    bool? isPixVerified,
  }) {
    return AdModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userAvatar: userAvatar ?? this.userAvatar,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      images: images ?? this.images,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      district: district ?? this.district,
      contactPhone: contactPhone ?? this.contactPhone,
      allowWhatsApp: allowWhatsApp ?? this.allowWhatsApp,
      planId: planId ?? this.planId,
      isFeatured: isFeatured ?? this.isFeatured,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewsCount: viewsCount ?? this.viewsCount,
      specificFields: specificFields ?? this.specificFields,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isPixVerified: isPixVerified ?? this.isPixVerified,
    );
  }
}
