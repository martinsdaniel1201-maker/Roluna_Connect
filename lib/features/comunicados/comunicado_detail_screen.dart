import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/admin_badge.dart';
import '../../core/widgets/priority_chip.dart';
import '../../providers/app_providers.dart';

final _comunicadoDetailProvider =
    FutureProvider.family((ref, String id) => ref.watch(comunicadosRepositoryProvider).buscarPorId(id));

final _jaConfirmouProvider = FutureProvider.family((ref, String id) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return false;
  return ref.watch(comunicadosRepositoryProvider).jaConfirmou(id, user.id);
});

class ComunicadoDetailScreen extends ConsumerWidget {
  final String comunicadoId;
  const ComunicadoDetailScreen({super.key, required this.comunicadoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comunicadoAsync = ref.watch(_comunicadoDetailProvider(comunicadoId));
    final jaConfirmouAsync = ref.watch(_jaConfirmouProvider(comunicadoId));
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunicado'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: 'Ver confirmações de leitura',
              onPressed: () => context.push('/comunicados/$comunicadoId/confirmacoes'),
            ),
        ],
      ),
      body: comunicadoAsync.when(
        data: (c) {
          final autorAdmin = c.autor?.isAdmin ?? false;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  PriorityChip(prioridade: c.prioridade),
                  const SizedBox(width: 8),
                  if (autorAdmin) const AdminBadge(),
                  const Spacer(),
                  if (c.fixado) const Icon(Icons.push_pin, size: 18, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 14),
              Text(c.titulo, style: AppTextStyles.displayLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.surfaceAlt,
                    child: Text(c.autor?.iniciais ?? '?', style: AppTextStyles.caption),
                  ),
                  const SizedBox(width: 8),
                  Text(c.autor?.nomeCompleto ?? 'Autor', style: AppTextStyles.bodyMuted),
                  const SizedBox(width: 8),
                  Text('· ${DateFormatters.dataHora(c.createdAt)}', style: AppTextStyles.caption),
                ],
              ),
              const Divider(height: 32),
              Text(c.descricao, style: AppTextStyles.body),

              if (c.exigeConfirmacao) ...[
                const SizedBox(height: 24),
                jaConfirmouAsync.when(
                  data: (confirmado) => _ConfirmacaoBox(
                    comunicadoId: comunicadoId,
                    jaConfirmou: confirmado,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],

              const SizedBox(height: 24),
              Row(
                children: [
                  _AcaoIcone(
                    icon: c.curtidoPeloUsuario ? Icons.favorite : Icons.favorite_border,
                    label: '${c.totalLikes} curtidas',
                    color: c.curtidoPeloUsuario ? AppColors.urgente : AppColors.textSecondary,
                    onTap: () async {
                      final user = await ref.read(currentUserProvider.future);
                      if (user == null) return;
                      final repo = ref.read(comunicadosRepositoryProvider);
                      if (c.curtidoPeloUsuario) {
                        await repo.descurtir(comunicadoId, user.id);
                      } else {
                        await repo.curtir(comunicadoId, user.id);
                      }
                      ref.invalidate(_comunicadoDetailProvider(comunicadoId));
                    },
                  ),
                  const SizedBox(width: 24),
                  _AcaoIcone(
                    icon: Icons.mode_comment_outlined,
                    label: '${c.totalComentarios} comentários',
                    color: AppColors.textSecondary,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Erro ao carregar comunicado: $e')),
      ),
    );
  }
}

class _ConfirmacaoBox extends ConsumerWidget {
  final String comunicadoId;
  final bool jaConfirmou;
  const _ConfirmacaoBox({required this.comunicadoId, required this.jaConfirmou});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: jaConfirmou ? AppColors.success.withOpacity(0.08) : AppColors.obrigatorio.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: jaConfirmou ? AppColors.success.withOpacity(0.4) : AppColors.obrigatorio.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                jaConfirmou ? Icons.check_circle : Icons.warning_amber_rounded,
                color: jaConfirmou ? AppColors.success : AppColors.obrigatorio,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  jaConfirmou
                      ? 'Você já confirmou a leitura deste comunicado.'
                      : 'Este comunicado é obrigatório e exige sua confirmação de leitura.',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (!jaConfirmou) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.obrigatorio),
                icon: const Icon(Icons.check),
                label: const Text('Li e estou ciente'),
                onPressed: () async {
                  final user = await ref.read(currentUserProvider.future);
                  if (user == null) return;
                  await ref.read(comunicadosRepositoryProvider).confirmarLeitura(comunicadoId, user.id);
                  ref.invalidate(_jaConfirmouProvider(comunicadoId));
                  ref.invalidate(_comunicadoDetailProvider(comunicadoId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Leitura confirmada com sucesso.')),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AcaoIcone extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AcaoIcone({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.bodyMuted),
          ],
        ),
      ),
    );
  }
}
