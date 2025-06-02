import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://erp.comsindia.in/api';
  static String get loginEndpoint =>
      '${apiBaseUrl}${dotenv.env['API_LOGIN_ENDPOINT'] ?? '/login'}';
}
