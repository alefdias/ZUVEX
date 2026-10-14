class CityModel {
  final String id;
  final String name;
  final String state;
  final bool isDefault;
  final bool active;

  const CityModel({
    required this.id,
    required this.name,
    required this.state,
    this.isDefault = false,
    this.active = true,
  });

  String get displayName => '$name – $state';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'isDefault': isDefault,
      'active': active,
    };
  }

  factory CityModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CityModel(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      state: map['state'] ?? 'SP',
      isDefault: map['isDefault'] ?? false,
      active: map['active'] ?? true,
    );
  }

  // Lista inicial de cidades suportadas (expansível via Firestore)
  static const CityModel promissao = CityModel(
    id: 'promissao_sp',
    name: 'Promissão',
    state: 'SP',
    isDefault: true,
    active: true,
  );

  static const CityModel lins = CityModel(
    id: 'lins_sp',
    name: 'Lins',
    state: 'SP',
    isDefault: false,
    active: true,
  );

  static const List<CityModel> defaultCities = [
    promissao,
    lins,
    CityModel(id: 'getulina_sp', name: 'Getulina', state: 'SP'),
    CityModel(id: 'guaiçara_sp', name: 'Guaiçara', state: 'SP'),
    CityModel(id: 'avanhadava_sp', name: 'Avanhandava', state: 'SP'),
    CityModel(id: 'penapolis_sp', name: 'Penápolis', state: 'SP'),
  ];
}
