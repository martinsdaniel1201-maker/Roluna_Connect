import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/supabase/supabase_client_provider.dart';
import '../data/models/user_model.dart';

class UsersRepository {
  final SupabaseClient _client = supabase;

  Future<List<UserModel>> listarTodos() async {
    final data = await _client.from('profiles').select().eq('ativo', true).order('nome_completo');
    return (data as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Aniversariantes do dia (Home) — filtra client-side pelo mês/dia
  /// já que Postgres precisa de extract(month/day) via RPC para eficiência.
  /// Aqui usamos a RPC `aniversariantes_do_dia` (a criar no Supabase) como
  /// abordagem recomendada; fallback simplificado abaixo busca o mês inteiro.
  Future<List<UserModel>> aniversariantesDoMes(int mes) async {
    final data = await _client.from('profiles').select().eq('ativo', true).not('data_nascimento', 'is', null);

    final todos = (data as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
    return todos.where((u) => u.dataNascimento != null && u.dataNascimento!.month == mes).toList()
      ..sort((a, b) => a.dataNascimento!.day.compareTo(b.dataNascimento!.day));
  }

  Future<void> atualizarRole(String userId, UserRole role) async {
    await _client.from('profiles').update({'role': role.asString}).eq('id', userId);
  }

  Future<void> desativar(String userId) async {
    await _client.from('profiles').update({'ativo': false}).eq('id', userId);
  }
}
