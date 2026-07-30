import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client_provider.dart';
import '../data/models/comunicado_model.dart';
import '../data/models/confirmacao_model.dart';

/// Encapsula todo o acesso a dados de comunicados.
///
/// Observação: as queries abaixo assumem que os campos agregados
/// (total_likes, curtido_pelo_usuario, etc.) serão resolvidos por
/// RPC/views no Supabase. Aqui usamos `select` com joins simples e
/// deixamos marcado onde uma RPC dedicada (ex.: `get_comunicados_feed`)
/// deve substituir a query composta para melhor performance em produção.
class ComunicadosRepository {
  final SupabaseClient _client = supabase;

  Future<List<ComunicadoModel>> listar({
    String? categoria,
    bool apenasFixados = false,
    int limit = 30,
  }) async {
    var query = _client
        .from('comunicados')
        .select('*, autor:profiles!comunicados_autor_id_fkey(*)')
        .eq('status', 'publicado');

    if (categoria != null) query = query.eq('categoria', categoria);
    if (apenasFixados) query = query.eq('fixado', true);

    final data = await query.order('fixado', ascending: false).order('publicar_em', ascending: false).limit(limit);

    return (data as List).map((e) => ComunicadoModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ComunicadoModel> buscarPorId(String id) async {
    final data = await _client
        .from('comunicados')
        .select('*, autor:profiles!comunicados_autor_id_fkey(*)')
        .eq('id', id)
        .single();
    return ComunicadoModel.fromJson(data);
  }

  Future<void> criar(ComunicadoModel comunicado, String autorId) async {
    await _client.from('comunicados').insert({
      ...comunicado.toInsertJson(),
      'autor_id': autorId,
      'status': comunicado.publicarEm.isAfter(DateTime.now()) ? 'agendado' : 'publicado',
    });
  }

  Future<void> atualizar(String id, Map<String, dynamic> campos) async {
    await _client.from('comunicados').update(campos).eq('id', id);
  }

  Future<void> excluir(String id) async {
    await _client.from('comunicados').delete().eq('id', id);
  }

  // ---- Confirmação de leitura -------------------------------------------

  Future<void> confirmarLeitura(String comunicadoId, String usuarioId) async {
    await _client.from('confirmacoes_leitura').insert({
      'comunicado_id': comunicadoId,
      'usuario_id': usuarioId,
    });
  }

  Future<bool> jaConfirmou(String comunicadoId, String usuarioId) async {
    final data = await _client
        .from('confirmacoes_leitura')
        .select('id')
        .eq('comunicado_id', comunicadoId)
        .eq('usuario_id', usuarioId)
        .maybeSingle();
    return data != null;
  }

  Future<List<ConfirmacaoModel>> listarConfirmacoes(String comunicadoId) async {
    final data = await _client
        .from('confirmacoes_leitura')
        .select('*, usuario:profiles!confirmacoes_leitura_usuario_id_fkey(*)')
        .eq('comunicado_id', comunicadoId)
        .order('confirmado_em', ascending: false);
    return (data as List).map((e) => ConfirmacaoModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Retorna estatísticas de leitura: total de colaboradores, confirmados e pendentes.
  Future<Map<String, dynamic>> estatisticasLeitura(String comunicadoId) async {
    final confirmados = await _client
        .from('confirmacoes_leitura')
        .select('id')
        .eq('comunicado_id', comunicadoId)
        .count(CountOption.exact);

    final totalColaboradores =
        await _client.from('profiles').select('id').eq('ativo', true).count(CountOption.exact);

    final total = totalColaboradores.count;
    final lidos = confirmados.count;
    return {
      'total_colaboradores': total,
      'total_confirmados': lidos,
      'pendentes': total - lidos,
      'percentual': total == 0 ? 0.0 : lidos / total,
    };
  }

  // ---- Curtidas / comentários --------------------------------------------

  Future<void> curtir(String comunicadoId, String usuarioId) async {
    await _client.from('comunicado_likes').insert({'comunicado_id': comunicadoId, 'usuario_id': usuarioId});
  }

  Future<void> descurtir(String comunicadoId, String usuarioId) async {
    await _client
        .from('comunicado_likes')
        .delete()
        .eq('comunicado_id', comunicadoId)
        .eq('usuario_id', usuarioId);
  }

  Future<void> comentar(String comunicadoId, String autorId, String texto) async {
    await _client.from('comunicado_comentarios').insert({
      'comunicado_id': comunicadoId,
      'autor_id': autorId,
      'texto': texto,
    });
  }
}
