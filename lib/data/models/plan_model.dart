class PlanModel {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final bool isFeatured;
  final String description;
  final List<String> benefits;

  const PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.isFeatured,
    required this.description,
    required this.benefits,
  });

  String get formattedPrice => 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'isFeatured': isFeatured,
      'description': description,
      'benefits': benefits,
    };
  }

  factory PlanModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return PlanModel(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 5.0,
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 30,
      isFeatured: map['isFeatured'] ?? false,
      description: map['description'] ?? '',
      benefits: List<String>.from(map['benefits'] ?? []),
    );
  }

  // ─────────────────────────────────────────────
  // 🧪 MODO TESTE — preços R$ 0,01 para testar Pix
  // Para restaurar valores reais, troque os preços abaixo:
  //   basic    → 5.0   (R$ 5,00)
  //   extended → 8.0   (R$ 8,00)
  //   featured → 15.0  (R$ 15,00)
  // ─────────────────────────────────────────────

  static const PlanModel basic = PlanModel(
    id: 'basic',
    name: 'Plano Básico',
    price: 0.01, // REAL: 5.0
    durationDays: 30,
    isFeatured: false,
    description: 'Ideal para vendas rápidas no dia a dia.',
    benefits: [
      'Anúncio ativo por 30 dias',
      'Exibição na sua cidade e região',
      'Até 10 fotos em alta qualidade',
      'Botão direto para seu WhatsApp',
    ],
  );

  static const PlanModel extended = PlanModel(
    id: 'extended',
    name: 'Plano Estendido',
    price: 0.01, // REAL: 8.0
    durationDays: 60,
    isFeatured: false,
    description: 'Mais tempo para encontrar o comprador certo.',
    benefits: [
      'Anúncio ativo por 60 dias (o dobro de tempo)',
      'Excelente custo-benefício',
      'Até 10 fotos em alta qualidade',
      'Botão direto para seu WhatsApp',
    ],
  );

  static const PlanModel featured = PlanModel(
    id: 'featured',
    name: 'Plano Destaque',
    price: 0.01, // REAL: 15.0
    durationDays: 60,
    isFeatured: true,
    description: 'Máxima visibilidade no topo e com selo ouro.',
    benefits: [
      'Anúncio ativo por 60 dias',
      'Prioridade no topo da página inicial',
      'Selo dourado de Anúncio Destaque',
      'Até 3x mais contatos no WhatsApp',
      'Até 10 fotos em alta qualidade',
    ],
  );

  static const List<PlanModel> defaultPlans = [
    basic,
    extended,
    featured,
  ];

  static PlanModel findById(String id) {
    return defaultPlans.firstWhere(
      (p) => p.id.toLowerCase() == id.toLowerCase(),
      orElse: () => basic,
    );
  }
}
