import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client_provider.dart';
import '../data/models/ramal_model.dart';

class RamaisRepository {
  final SupabaseClient _client = supabase;

  /// Retorna setores com seus ramais agrupados, ordenados por departamento.
  Future<List<SetorModel>> listarAgrupado() async {
    final setoresData = await _client.from('setores').select().order('ordem');
    final ramaisData = await _client.from('ramais').select().order('nome_local');

    final ramais = (ramaisData as List)
        .map((e) => (e as Map<String, dynamic>, RamalModel.fromJson(e)))
        .toList();

    return (setoresData as List).map((s) {
      final setorMap = s as Map<String, dynamic>;
      final ramaisDoSetor = ramais
          .where((r) => r.$1['setor_id'] == setorMap['id'])
          .map((r) => r.$2)
          .toList();
      return SetorModel(
        id: setorMap['id'] as String,
        nome: setorMap['nome'] as String,
        departamento: setorMap['departamento'] as String?,
        ramais: ramaisDoSetor,
      );
    }).toList();
  }
}
