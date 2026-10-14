import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad_model.dart';
import '../models/city_model.dart';
import '../models/payment_transaction_model.dart';
import '../models/report_model.dart';
import '../../main.dart' show firebaseReady;

class AdService {
  static FirebaseFirestore? get _db => firebaseReady ? FirebaseFirestore.instance : null;

  // Coleções
  static CollectionReference? get _adsRef => _db?.collection('ads');
  static CollectionReference? get _citiesRef => _db?.collection('cities');
  static CollectionReference? get _transactionsRef => _db?.collection('transactions');
  static CollectionReference? get _reportsRef => _db?.collection('reports');

  // Stream ou Fetch de Anúncios Ativos
  static Stream<List<AdModel>> streamActiveAds({String? cityId, String? categoryId}) {
    if (_adsRef == null) {
      return Stream.value(getInitialMockAds());
    }

    Query query = _adsRef!.where('status', isEqualTo: 'active');

    if (cityId != null && cityId.isNotEmpty && cityId != 'todas') {
      query = query.where('cityId', isEqualTo: cityId);
    }

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'todas' && categoryId != 'all') {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots().map((snap) {
      final list = snap.docs.map((d) {
        return AdModel.fromMap(d.data() as Map<String, dynamic>, id: d.id);
      }).toList();

      // Ordenar: Destaques primeiro, depois por data decrescente
      list.sort((a, b) {
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      return list;
    });
  }

  // Meus Anúncios por Usuário
  static Stream<List<AdModel>> streamUserAds(String userId) {
    if (_adsRef == null) {
      return Stream.value(getInitialMockAds());
    }
    return _adsRef!
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) {
            return AdModel.fromMap(d.data() as Map<String, dynamic>, id: d.id);
          }).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Obter Anúncio por ID
  static Future<AdModel?> getAdById(String adId) async {
    if (_adsRef == null) {
      return getInitialMockAds().firstWhere((a) => a.id == adId, orElse: () => getInitialMockAds().first);
    }
    try {
      final doc = await _adsRef!.doc(adId).get();
      if (!doc.exists) return null;
      return AdModel.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
    } catch (_) {
      return null;
    }
  }

  // Incrementar Contador de Visualizações
  static Future<void> incrementViews(String adId) async {
    if (_adsRef == null) return;
    try {
      await _adsRef!.doc(adId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  // Criar Novo Anúncio
  static Future<String> createAd(AdModel ad) async {
    if (_adsRef == null) {
      return 'ad_local_${DateTime.now().millisecondsSinceEpoch}';
    }
    final docRef = _adsRef!.doc();
    final newAd = ad.copyWith(id: docRef.id);
    await docRef.set(newAd.toMap());
    return docRef.id;
  }

  // Atualizar Status do Anúncio (Ex: Marcar como Vendido, Remover, etc.)
  static Future<void> updateAdStatus(String adId, AdStatus status, {String? rejectionReason}) async {
    if (_adsRef == null) return;
    final data = <String, dynamic>{
      'status': status.toDbValue(),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
    await _adsRef!.doc(adId).update(data);
  }

  // Renovar Anúncio Expirado
  static Future<void> renewAd(String adId, int durationDays) async {
    if (_adsRef == null) return;
    final newExpiry = DateTime.now().add(Duration(days: durationDays));
    await _adsRef!.doc(adId).update({
      'status': 'active',
      'expiresAt': Timestamp.fromDate(newExpiry),
    });
  }

  // Excluir Anúncio
  static Future<void> deleteAd(String adId) async {
    if (_adsRef == null) return;
    await _adsRef!.doc(adId).delete();
  }

  // Criar Transação de Pagamento Pix
  static Future<void> createTransaction(PaymentTransactionModel tx) async {
    if (_transactionsRef == null) return;
    await _transactionsRef!.doc(tx.id).set(tx.toMap());
  }

  // Confirmar Pagamento e Ativar Anúncio Automaticamente
  static Future<void> confirmPaymentAndActivateAd({
    required String transactionId,
    required String adId,
    required int durationDays,
  }) async {
    if (_db != null && _transactionsRef != null && _adsRef != null) {
      try {
        final batch = _db!.batch();

        // 1. Atualizar transação
        final txRef = _transactionsRef!.doc(transactionId);
        batch.update(txRef, {
          'status': 'confirmed',
          'confirmedAt': FieldValue.serverTimestamp(),
        });

        // 2. Ativar anúncio com expiração calculada e selo de Pix Verificado
        final adRef = _adsRef!.doc(adId);
        final expiresAt = DateTime.now().add(Duration(days: durationDays));
        batch.update(adRef, {
          'status': 'active',
          'isPixVerified': true,
          'expiresAt': Timestamp.fromDate(expiresAt),
        });

        await batch.commit();
      } catch (_) {}
    }
  }

  // Criar Denúncia de Anúncio
  static Future<void> createReport(ReportModel report) async {
    if (_reportsRef == null) return;
    final docRef = _reportsRef!.doc();
    await docRef.set(report.toMap());
  }

  // Buscar Cidades Disponíveis
  static Future<List<CityModel>> fetchCities() async {
    if (_citiesRef == null) return CityModel.defaultCities;
    try {
      final snap = await _citiesRef!.where('active', isEqualTo: true).get();
      if (snap.docs.isEmpty) return CityModel.defaultCities;
      return snap.docs
          .map((d) => CityModel.fromMap(d.data() as Map<String, dynamic>, id: d.id))
          .toList();
    } catch (_) {
      return CityModel.defaultCities;
    }
  }

  // Dados Iniciais Realistas de Promissão e Região para Demonstração Inicial Offline/Online
  static List<AdModel> getInitialMockAds() {
    final now = DateTime.now();
    return [
      AdModel(
        id: 'ad_promissao_1',
        userId: 'user_promissao_1',
        userName: 'Carlos Silva',
        userEmail: 'carlos.promissao@gmail.com',
        title: 'Toyota Corolla XEi 2.0 Flex Automático',
        description: 'Carro em estado impecável, único dono, revisões feitas na concessionária. Pneus novos, ar-condicionado digital, multimídia com CarPlay. Documentação 2026 em dia.',
        price: 92500.0,
        categoryId: 'carros',
        images: [
          'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1590362891991-f776e747a588?w=800&auto=format&fit=crop&q=80',
        ],
        cityId: 'promissao_sp',
        cityName: 'Promissão - SP',
        district: 'Jardim das Flores',
        contactPhone: '14998765432',
        allowWhatsApp: true,
        planId: 'featured',
        isFeatured: true,
        status: AdStatus.active,
        createdAt: now.subtract(const Duration(hours: 3)),
        expiresAt: now.add(const Duration(days: 60)),
        viewsCount: 142,
        specificFields: {
          'marca': 'Toyota',
          'modelo': 'Corolla XEi',
          'ano': '2021',
          'quilometragem': '48000',
          'combustivel': 'Flex',
          'cambio': 'Automático',
        },
      ),
      AdModel(
        id: 'ad_promissao_2',
        userId: 'user_promissao_2',
        userName: 'Mariana Oliveira',
        userEmail: 'mariana.corretora@gmail.com',
        title: 'Casa ampla com 3 quartos e piscina',
        description: 'Excelente casa térrea com 3 quartos (1 suíte), sala ampla em 2 ambientes, cozinha planejada, área gourmet completa com churrasqueira e piscina. Garagem para 2 carros cobertos.',
        price: 430000.0,
        categoryId: 'imoveis',
        images: [
          'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&auto=format&fit=crop&q=80',
        ],
        cityId: 'promissao_sp',
        cityName: 'Promissão - SP',
        district: 'Centro',
        contactPhone: '14991234567',
        allowWhatsApp: true,
        planId: 'featured',
        isFeatured: true,
        status: AdStatus.active,
        createdAt: now.subtract(const Duration(hours: 6)),
        expiresAt: now.add(const Duration(days: 60)),
        viewsCount: 230,
        specificFields: {
          'tipo_imovel': 'Casa',
          'area': '220',
          'quartos': '3',
          'banheiros': '2',
          'vagas': '2',
        },
      ),
      AdModel(
        id: 'ad_promissao_3',
        userId: 'user_promissao_3',
        userName: 'Lucas Mecânico',
        userEmail: 'lucas.motos@gmail.com',
        title: 'Honda CB 500F Abs Impecável',
        description: 'Moto muito bem cuidada, apenas 18.000 km rodados, revisada recentemente com óleo Motul trocado. Sem detalhes, pronta para transferir.',
        price: 36000.0,
        categoryId: 'motos',
        images: [
          'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&auto=format&fit=crop&q=80',
        ],
        cityId: 'promissao_sp',
        cityName: 'Promissão - SP',
        district: 'Vila Nova',
        contactPhone: '14997654321',
        allowWhatsApp: true,
        planId: 'basic',
        isFeatured: false,
        status: AdStatus.active,
        createdAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 29)),
        viewsCount: 88,
        specificFields: {
          'marca': 'Honda',
          'modelo': 'CB 500F',
          'ano': '2022',
          'cilindrada': '500',
          'quilometragem': '18000',
        },
      ),
      AdModel(
        id: 'ad_promissao_4',
        userId: 'user_promissao_4',
        userName: 'Roberto Santos',
        userEmail: 'roberto.agro@gmail.com',
        title: 'Terreno comercial em avenida principal',
        description: 'Ótimo lote plaino pronto para construir barracão ou ponto comercial. Medindo 12x30 (360m²), com toda infraestrutura de água, asfalto e luz.',
        price: 155000.0,
        categoryId: 'terrenos',
        images: [
          'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800&auto=format&fit=crop&q=80',
        ],
        cityId: 'promissao_sp',
        cityName: 'Promissão - SP',
        district: 'Avenida Pedro de Toledo',
        contactPhone: '14996549870',
        allowWhatsApp: true,
        planId: 'extended',
        isFeatured: false,
        status: AdStatus.active,
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(days: 58)),
        viewsCount: 64,
        specificFields: {
          'area_terreno': '360',
          'tipo_terreno': 'Comercial',
        },
      ),
      AdModel(
        id: 'ad_promissao_5',
        userId: 'user_promissao_5',
        userName: 'Aline Tech',
        userEmail: 'aline.tecnologia@gmail.com',
        title: 'iPhone 14 Pro Max 256GB Roxo Profundo',
        description: 'Aparelho em estado de zero, bateria em 91%, acompanha caixa original, cabo USB-C e duas capinhas de brinde. Nunca aberto, com película aplicada.',
        price: 5200.0,
        categoryId: 'eletronicos',
        images: [
          'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800&auto=format&fit=crop&q=80',
        ],
        cityId: 'promissao_sp',
        cityName: 'Promissão - SP',
        district: 'Centro',
        contactPhone: '14995432109',
        allowWhatsApp: true,
        planId: 'basic',
        isFeatured: false,
        status: AdStatus.active,
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(days: 28)),
        viewsCount: 119,
        specificFields: {
          'marca': 'Apple',
          'modelo': 'iPhone 14 Pro Max',
          'condicao': 'Excelente',
        },
      ),
    ];
  }
}
