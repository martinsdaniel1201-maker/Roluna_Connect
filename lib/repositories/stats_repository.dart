import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client_provider.dart';

class StatsRepository {
  final SupabaseClient _client = supabase;

  /// Lê a view `vw_admin_dashboard` criada no schema.sql.
  Future<Map<String, dynamic>> dashboard() async {
    final data = await _client.from('vw_admin_dashboard').select().single();
    return data;
  }

  /// Lista de comunicados obrigatórios com percentual de leitura (view vw_comunicado_stats).
  Future<List<Map<String, dynamic>>> comunicadosObrigatoriosStats() async {
    final data = await _client
        .from('vw_comunicado_stats')
        .select()
        .eq('obrigatorio', true)
        .order('comunicado_id');
    return (data as List).cast<Map<String, dynamic>>();
  }
}
