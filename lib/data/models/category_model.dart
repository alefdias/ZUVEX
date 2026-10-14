import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CategoryModel {
  final String id;
  final String title;
  final IconData icon;
  final List<CategoryField> specificFields;

  const CategoryModel({
    required this.id,
    required this.title,
    required this.icon,
    this.specificFields = const [],
  });

  static const List<CategoryModel> allCategories = [
    CategoryModel(
      id: 'carros',
      title: 'Carros',
      icon: Iconsax.car,
      specificFields: [
        CategoryField(id: 'marca', label: 'Marca', required: true),
        CategoryField(id: 'modelo', label: 'Modelo', required: true),
        CategoryField(id: 'ano', label: 'Ano', keyboardType: TextInputType.number, required: true),
        CategoryField(id: 'quilometragem', label: 'Quilometragem (KM)', keyboardType: TextInputType.number, required: true),
        CategoryField(
          id: 'combustivel',
          label: 'Combustível',
          options: ['Flex', 'Gasolina', 'Etanol', 'Diesel', 'Híbrido', 'Elétrico'],
          required: true,
        ),
        CategoryField(
          id: 'cambio',
          label: 'Câmbio',
          options: ['Manual', 'Automático', 'Automatizado'],
        ),
      ],
    ),
    CategoryModel(
      id: 'motos',
      title: 'Motos',
      icon: Iconsax.driving,
      specificFields: [
        CategoryField(id: 'marca', label: 'Marca', required: true),
        CategoryField(id: 'modelo', label: 'Modelo', required: true),
        CategoryField(id: 'ano', label: 'Ano', keyboardType: TextInputType.number, required: true),
        CategoryField(id: 'cilindrada', label: 'Cilindrada (cc)', keyboardType: TextInputType.number, required: true),
        CategoryField(id: 'quilometragem', label: 'Quilometragem (KM)', keyboardType: TextInputType.number, required: true),
      ],
    ),
    CategoryModel(
      id: 'imoveis',
      title: 'Imóveis',
      icon: Iconsax.house,
      specificFields: [
        CategoryField(
          id: 'tipo_imovel',
          label: 'Tipo',
          options: ['Casa', 'Apartamento', 'Chácara', 'Comercial', 'Temporada'],
          required: true,
        ),
        CategoryField(id: 'area', label: 'Área (m²)', keyboardType: TextInputType.number, required: true),
        CategoryField(id: 'quartos', label: 'Quartos', keyboardType: TextInputType.number),
        CategoryField(id: 'banheiros', label: 'Banheiros', keyboardType: TextInputType.number),
        CategoryField(id: 'vagas', label: 'Vagas de garagem', keyboardType: TextInputType.number),
      ],
    ),
    CategoryModel(
      id: 'terrenos',
      title: 'Terrenos',
      icon: Iconsax.map,
      specificFields: [
        CategoryField(id: 'area_terreno', label: 'Área Total (m²)', keyboardType: TextInputType.number, required: true),
        CategoryField(
          id: 'tipo_terreno',
          label: 'Tipo',
          options: ['Urbano', 'Condomínio Fechado', 'Rural / Sítio', 'Comercial'],
        ),
      ],
    ),
    CategoryModel(
      id: 'eletronicos',
      title: 'Eletrônicos',
      icon: Iconsax.mobile,
      specificFields: [
        CategoryField(id: 'marca', label: 'Marca'),
        CategoryField(id: 'modelo', label: 'Modelo'),
        CategoryField(
          id: 'condicao',
          label: 'Condição',
          options: ['Novo / Lacrado', 'Excelente', 'Bom', 'Marcas de uso', 'Para conserto'],
          required: true,
        ),
      ],
    ),
    CategoryModel(
      id: 'informatica',
      title: 'Informática',
      icon: Iconsax.monitor,
      specificFields: [
        CategoryField(
          id: 'tipo_dispositivo',
          label: 'Tipo',
          options: ['Notebook', 'Desktop / PC Gamer', 'Monitor', 'Componente / Peça', 'Periférico', 'Outro'],
        ),
        CategoryField(id: 'marca', label: 'Marca'),
        CategoryField(id: 'memoria_ram', label: 'Memória RAM (GB)'),
        CategoryField(id: 'armazenamento', label: 'Armazenamento (SSD/HD)'),
      ],
    ),
    CategoryModel(
      id: 'moveis',
      title: 'Móveis',
      icon: Iconsax.lamp_charge,
      specificFields: [
        CategoryField(id: 'material', label: 'Material'),
        CategoryField(
          id: 'condicao',
          label: 'Condição',
          options: ['Novo', 'Semi-novo', 'Usado'],
        ),
      ],
    ),
    CategoryModel(
      id: 'eletrodomesticos',
      title: 'Eletrodomésticos',
      icon: Iconsax.smart_home,
      specificFields: [
        CategoryField(
          id: 'voltagem',
          label: 'Voltagem',
          options: ['110V', '220V', 'Bivolt'],
        ),
        CategoryField(id: 'marca', label: 'Marca'),
      ],
    ),
    CategoryModel(
      id: 'roupas',
      title: 'Roupas',
      icon: Iconsax.shop,
      specificFields: [
        CategoryField(id: 'tamanho', label: 'Tamanho (ex: P, M, G, 42)'),
        CategoryField(
          id: 'genero',
          label: 'Gênero / Categoria',
          options: ['Feminino', 'Masculino', 'Infantil', 'Unissex'],
        ),
      ],
    ),
    CategoryModel(
      id: 'servicos',
      title: 'Serviços',
      icon: Iconsax.briefcase,
      specificFields: [
        CategoryField(id: 'area_atuacao', label: 'Área / Especialidade', required: true),
        CategoryField(id: 'disponibilidade', label: 'Disponibilidade (ex: Segunda a Sábado)'),
      ],
    ),
    CategoryModel(
      id: 'empregos',
      title: 'Empregos',
      icon: Iconsax.user_search,
      specificFields: [
        CategoryField(id: 'cargo', label: 'Cargo / Função', required: true),
        CategoryField(
          id: 'regime',
          label: 'Regime de Contratação',
          options: ['CLT', 'PJ', 'Temporário', 'Estágio', 'Freelance'],
        ),
        CategoryField(id: 'remuneracao', label: 'Faixa Salarial / A Combinar'),
      ],
    ),
    CategoryModel(
      id: 'outros',
      title: 'Outros',
      icon: Iconsax.more_circle,
      specificFields: [],
    ),
  ];

  static CategoryModel findById(String id) {
    return allCategories.firstWhere(
      (c) => c.id.toLowerCase() == id.toLowerCase(),
      orElse: () => allCategories.last,
    );
  }
}

class CategoryField {
  final String id;
  final String label;
  final TextInputType keyboardType;
  final bool required;
  final List<String>? options;

  const CategoryField({
    required this.id,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.required = false,
    this.options,
  });
}
