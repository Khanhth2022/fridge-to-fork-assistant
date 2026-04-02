import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get edamamAppId {
    final String? appIdFromEnv = dotenv.env['EDAMAM_APP_ID'];
    if (appIdFromEnv != null && appIdFromEnv.trim().isNotEmpty) {
      return appIdFromEnv;
    }
    return const String.fromEnvironment('EDAMAM_APP_ID');
  }

  static String get edamamAppKey {
    final String? appKeyFromEnv = dotenv.env['EDAMAM_APP_KEY'];
    if (appKeyFromEnv != null && appKeyFromEnv.trim().isNotEmpty) {
      return appKeyFromEnv;
    }
    return const String.fromEnvironment('EDAMAM_APP_KEY');
  }

  static String get edamamAccountUser {
    final String? accountUserFromEnv = dotenv.env['EDAMAM_ACCOUNT_USER'];
    if (accountUserFromEnv != null && accountUserFromEnv.trim().isNotEmpty) {
      return accountUserFromEnv;
    }
    return const String.fromEnvironment('EDAMAM_ACCOUNT_USER');
  }

  static String get spoonacularApiKey {
    final String? keyFromEnv = dotenv.env['SPOONACULAR_API_KEY'];
    if (keyFromEnv != null && keyFromEnv.trim().isNotEmpty) {
      return keyFromEnv;
    }
    return const String.fromEnvironment('SPOONACULAR_API_KEY');
  }
}
