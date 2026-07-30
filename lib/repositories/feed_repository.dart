import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client_provider.dart';
import '../data/models/post_model.dart';
import '../data/models/comment_model.dart';

class FeedRepository {
  final SupabaseClient _client = supabase;

  Future<List<PostModel>> listarPosts({int limit = 30}) async {
    final data = await _client
        .from('posts')
        .select('*, autor:profiles!posts_autor_id_fkey(*)')
        .eq('status', 'publicado')
        .order('publicar_em', ascending: false)
        .limit(limit);
    return (data as List).map((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> criarPost({
    required String autorId,
    required String texto,
    String? anexoUrl,
    String? anexoTipo,
    DateTime? publicarEm,
  }) async {
    final agendado = publicarEm != null && publicarEm.isAfter(DateTime.now());
    await _client.from('posts').insert({
      'autor_id': autorId,
      'texto': texto,
      'anexo_url': anexoUrl,
      'anexo_tipo': anexoTipo,
      'publicar_em': (publicarEm ?? DateTime.now()).toIso8601String(),
      'status': agendado ? 'agendado' : 'publicado',
    });
  }

  Future<void> excluirPost(String id) async {
    await _client.from('posts').delete().eq('id', id);
  }

  Future<void> curtir(String postId, String usuarioId) async {
    await _client.from('post_likes').insert({'post_id': postId, 'usuario_id': usuarioId});
  }

  Future<void> descurtir(String postId, String usuarioId) async {
    await _client.from('post_likes').delete().eq('post_id', postId).eq('usuario_id', usuarioId);
  }

  Future<List<CommentModel>> listarComentarios(String postId) async {
    final data = await _client
        .from('post_comentarios')
        .select('*, autor:profiles!post_comentarios_autor_id_fkey(*)')
        .eq('post_id', postId)
        .order('created_at');
    return (data as List).map((e) => CommentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> comentar(String postId, String autorId, String texto) async {
    await _client.from('post_comentarios').insert({
      'post_id': postId,
      'autor_id': autorId,
      'texto': texto,
    });
  }
}
