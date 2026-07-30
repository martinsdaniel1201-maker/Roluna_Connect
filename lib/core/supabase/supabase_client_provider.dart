import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// Inicialização única do Supabase. Chamado em main() antes de runApp.
class SupabaseInit {
  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
}

/// Atalho global para o client, usado pelos repositories.
SupabaseClient get supabase => Supabase.instance.client;
