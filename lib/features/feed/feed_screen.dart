import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/admin_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/app_providers.dart';
import '../../data/models/post_model.dart';

final _postsProvider = FutureProvider((ref) => ref.watch(feedRepositoryProvider).listarPosts());

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(_postsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirNovoPost(context, ref),
        child: const Icon(Icons.edit),
      ),
      body: posts.when(
        data: (lista) {
          if (lista.isEmpty) {
            return const EmptyState(
              icon: Icons.forum_outlined,
              title: 'Nenhuma publicação ainda',
              subtitle: 'Seja o primeiro a compartilhar algo com a equipe!',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_postsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lista.length,
              itemBuilder: (context, i) => _PostCard(post: lista[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Erro ao carregar o feed: $e')),
      ),
    );
  }

  void _abrirNovoPost(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nova publicação', style: AppTextStyles.title),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Compartilhe algo com a equipe...'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.image_outlined), onPressed: () {}),
                IconButton(icon: const Icon(Icons.attach_file), onPressed: () {}),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    if (ctrl.text.trim().isEmpty) return;
                    final user = await ref.read(currentUserProvider.future);
                    if (user == null) return;
                    await ref.read(feedRepositoryProvider).criarPost(autorId: user.id, texto: ctrl.text.trim());
                    ref.invalidate(_postsProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Publicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isAdminPost = post.autor.isAdmin;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        borderColor: isAdminPost ? AppColors.primary.withOpacity(0.3) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isAdminPost ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceAlt,
                  child: Text(
                    post.autor.iniciais,
                    style: TextStyle(color: isAdminPost ? AppColors.primary : AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(post.autor.nomeCompleto,
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (isAdminPost) ...[
                            const SizedBox(width: 6),
                            const AdminBadge(compact: true),
                          ],
                        ],
                      ),
                      Text(DateFormatters.tempoRelativo(post.createdAt), style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(post.texto, style: AppTextStyles.body),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  post.curtidoPeloUsuario ? Icons.favorite : Icons.favorite_border,
                  size: 17,
                  color: post.curtidoPeloUsuario ? AppColors.urgente : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text('${post.totalLikes}', style: AppTextStyles.caption),
                const SizedBox(width: 16),
                Icon(Icons.mode_comment_outlined, size: 17, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${post.totalComentarios}', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
