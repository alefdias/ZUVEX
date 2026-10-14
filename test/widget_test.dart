import 'package:flutter_test/flutter_test.dart';
import 'package:zuvex_app/data/models/ad_model.dart';
import 'package:zuvex_app/data/models/city_model.dart';
import 'package:zuvex_app/data/models/plan_model.dart';

void main() {
  group('ZUVEX Models & Business Rules Tests', () {
    test('Plano Básico, Estendido e Destaque possuem valores e durações corretos', () {
      expect(PlanModel.basic.price, 5.0);
      expect(PlanModel.basic.durationDays, 30);
      expect(PlanModel.basic.isFeatured, false);

      expect(PlanModel.extended.price, 8.0);
      expect(PlanModel.extended.durationDays, 60);
      expect(PlanModel.extended.isFeatured, false);

      expect(PlanModel.featured.price, 15.0);
      expect(PlanModel.featured.durationDays, 60);
      expect(PlanModel.featured.isFeatured, true);
    });

    test('Cidade padrão de inicialização é Promissão - SP', () {
      expect(CityModel.promissao.name, 'Promissão');
      expect(CityModel.promissao.state, 'SP');
      expect(CityModel.promissao.isDefault, true);
      expect(CityModel.promissao.displayName, 'Promissão – SP');
    });

    test('Formatação de preço de anúncio em Real (R\$)', () {
      final ad = AdModel(
        id: 'test_1',
        userId: 'user_1',
        userName: 'João',
        userEmail: 'joao@zuvex.com',
        title: 'Bicicleta Caloi Aro 29',
        description: 'Em perfeito estado',
        price: 1250.50,
        categoryId: 'outros',
        images: ['https://example.com/img.jpg'],
        cityId: 'promissao_sp',
        cityName: 'Promissão – SP',
        district: 'Centro',
        contactPhone: '14998765432',
        planId: 'basic',
        createdAt: DateTime.now(),
      );

      expect(ad.formattedPrice, 'R\$ 1250,50');
      expect(ad.isFeatured, false);
      expect(ad.isExpired, false);
    });

    test('Verificação de cálculo de expiração de anúncio', () {
      final now = DateTime.now();
      final expiredAd = AdModel(
        id: 'test_exp',
        userId: 'user_1',
        userName: 'João',
        userEmail: 'joao@zuvex.com',
        title: 'Item Expirado',
        description: 'Item antigo',
        price: 50.0,
        categoryId: 'outros',
        images: [],
        cityId: 'promissao_sp',
        cityName: 'Promissão – SP',
        district: 'Centro',
        contactPhone: '14998765432',
        planId: 'basic',
        createdAt: now.subtract(const Duration(days: 35)),
        expiresAt: now.subtract(const Duration(days: 5)),
      );

      expect(expiredAd.isExpired, true);
    });
  });
}
