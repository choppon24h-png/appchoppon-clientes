import '../../core/network/api_client.dart';
import '../../shared/models.dart';

class DashboardRepository {
  DashboardRepository(this._api);

  final ApiClient _api;

  Future<DashboardData> load() async {
    final responses = await Future.wait([
      _api.get('pontos/dashboard.php', requiresAuth: true),
      _api.get('clientes/profile.php', requiresAuth: true),
    ]);
    final profilePayload = Map<String, dynamic>.from(
      responses[1]['data'] as Map? ?? const {},
    );
    return DashboardData.fromJson(responses[0], profileJson: profilePayload);
  }
}
