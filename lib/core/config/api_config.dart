import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get spoonacularApiKey {
    final String? keyFromEnv = dotenv.env['SPOONACULAR_API_KEY'];
    if (keyFromEnv != null && keyFromEnv.trim().isNotEmpty) {
      return keyFromEnv;
    }
    return const String.fromEnvironment('SPOONACULAR_API_KEY');
  }
}
