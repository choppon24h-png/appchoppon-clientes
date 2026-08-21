class ApiConfig {
  const ApiConfig._();

  static const String defaultBaseUrl =
      'https://ochoppoficial.com.br/api/v1/';

  static const String baseUrl = String.fromEnvironment(
    'CHOPPON_API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  static Uri endpoint(String path, [Map<String, String>? query]) {
    final base = Uri.parse(baseUrl);
    return base.resolve(path).replace(queryParameters: query);
  }
}
