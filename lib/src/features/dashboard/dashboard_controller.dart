import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../shared/models.dart';
import 'dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this._repository);

  final DashboardRepository _repository;

  DashboardData? data;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _repository.load();
    } catch (error) {
      errorMessage = error is ApiException
          ? error.message
          : 'Nao foi possivel carregar o dashboard.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
