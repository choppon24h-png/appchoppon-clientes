import 'package:flutter_test/flutter_test.dart';

import 'package:appchoppon_clientes/src/core/config/api_config.dart';
import 'package:appchoppon_clientes/src/shared/models.dart';

void main() {
  test('usa endpoint HTTPS por padrao', () {
    expect(ApiConfig.baseUrl, startsWith('https://'));
    expect(ApiConfig.endpoint('pontos/dashboard.php').path, contains('/api/v1/pontos/dashboard.php'));
  });

  test('mapeia dashboard no contrato real do ERP', () {
    final dashboard = DashboardData.fromJson(
      {
        'success': true,
        'data': {
          'periodos': {
            'hoje': 1.5,
            'semana': 4.0,
            'mes': 8.0,
            'total': 10.0,
          },
          'total_consumos': 8,
          'valor_total': 150.0,
          'pontos': 12.5,
        },
      },
      profileJson: {
        'id': 9,
        'nome': 'Cliente',
        'email': 'cliente@example.com',
        'cpf_mascarado': '529.***.***-25',
        'nivel': {'name': 'Explorador'},
      },
    );

    expect(dashboard.profile.cpfMasked, '529.***.***-25');
    expect(dashboard.profile.name, 'Cliente');
    expect(dashboard.today.liters, 1.5);
    expect(dashboard.total.count, 8);
    expect(dashboard.total.amount, 150.0);
    expect(dashboard.cashbackBalance, 12.5);
  });

  test('mantem compatibilidade com o contrato de periodos em ingles', () {
    final dashboard = DashboardData.fromJson({
      'success': true,
      'data': {
        'profile': {
          'id': 9,
          'name': 'Cliente',
          'email': 'cliente@example.com',
          'cpf_masked': '529.***.***-25',
          'level': {'name': 'Explorador'},
        },
        'periods': {
          'today': {'liters': 1.5, 'amount': 24.0, 'count': 1},
          'week': {'liters': 4.0, 'amount': 60.0, 'count': 3},
          'month': {'liters': 8.0, 'amount': 120.0, 'count': 6},
          'total': {'liters': 10.0, 'amount': 150.0, 'count': 8},
        },
        'cashback_balance': 12.5,
      },
    });

    expect(dashboard.today.liters, 1.5);
    expect(dashboard.total.count, 8);
    expect(dashboard.cashbackBalance, 12.5);
  });
}
