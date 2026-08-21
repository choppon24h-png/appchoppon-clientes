class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
}

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.cpfMasked,
    required this.level,
    this.nickname,
  });

  final int id;
  final String name;
  final String email;
  final String cpfMasked;
  final String level;
  final String? nickname;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    final levelData = json['level'] ?? json['nivel'];
    final levelName = levelData is Map
        ? levelData['name']?.toString() ?? levelData['nome']?.toString()
        : levelData?.toString();
    return CustomerProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? json['nome']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      cpfMasked: json['cpf_masked']?.toString() ?? json['cpf_mascarado']?.toString() ?? '',
      level: levelName ?? 'Explorador',
      nickname: json['nickname']?.toString() ?? json['apelido']?.toString(),
    );
  }
}

class ConsumptionSummary {
  const ConsumptionSummary({
    required this.liters,
    required this.amount,
    required this.count,
  });

  final double liters;
  final double amount;
  final int count;

  factory ConsumptionSummary.fromJson(Map<String, dynamic> json) {
    return ConsumptionSummary(
      liters: (json['liters'] as num?)?.toDouble() ?? (json['litros'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? (json['valor'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? (json['consumos'] as num?)?.toInt() ?? 0,
    );
  }

  factory ConsumptionSummary.fromValue(
    dynamic liters, {
    double amount = 0,
    int count = 0,
  }) {
    return ConsumptionSummary(
      liters: (liters as num?)?.toDouble() ?? 0,
      amount: amount,
      count: count,
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.profile,
    required this.today,
    required this.week,
    required this.month,
    required this.total,
    required this.cashbackBalance,
  });

  final CustomerProfile profile;
  final ConsumptionSummary today;
  final ConsumptionSummary week;
  final ConsumptionSummary month;
  final ConsumptionSummary total;
  final double cashbackBalance;

  factory DashboardData.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? profileJson,
  }) {
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? json);
    final modernPeriods = Map<String, dynamic>.from(data['periods'] as Map? ?? const {});
    final apiPeriods = Map<String, dynamic>.from(data['periodos'] as Map? ?? const {});
    final profile = CustomerProfile.fromJson(
      profileJson ?? Map<String, dynamic>.from(data['profile'] as Map? ?? const {}),
    );
    final totalAmount = (data['valor_total'] as num?)?.toDouble() ?? 0;
    final totalCount = (data['total_consumos'] as num?)?.toInt() ?? 0;

    return DashboardData(
      profile: profile,
      today: modernPeriods.isNotEmpty
          ? ConsumptionSummary.fromJson(Map<String, dynamic>.from(modernPeriods['today'] as Map? ?? const {}))
          : ConsumptionSummary.fromValue(apiPeriods['hoje']),
      week: modernPeriods.isNotEmpty
          ? ConsumptionSummary.fromJson(Map<String, dynamic>.from(modernPeriods['week'] as Map? ?? const {}))
          : ConsumptionSummary.fromValue(apiPeriods['semana']),
      month: modernPeriods.isNotEmpty
          ? ConsumptionSummary.fromJson(Map<String, dynamic>.from(modernPeriods['month'] as Map? ?? const {}))
          : ConsumptionSummary.fromValue(apiPeriods['mes']),
      total: modernPeriods.isNotEmpty
          ? ConsumptionSummary.fromJson(Map<String, dynamic>.from(modernPeriods['total'] as Map? ?? const {}))
          : ConsumptionSummary.fromValue(
              apiPeriods['total'],
              amount: totalAmount,
              count: totalCount,
            ),
      cashbackBalance: (data['cashback_balance'] as num?)?.toDouble() ??
          (data['pontos'] as num?)?.toDouble() ??
          0,
    );
  }
}
