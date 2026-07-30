import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/admin_badge.dart';
import '../../core/widgets/priority_chip.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/app_providers.dart';
import '../../data/models/comunicado_model.dart';
import '../../data/models/user_model.dart';

final _fixadosProvider = FutureProvider((ref) =>
    ref.watch(comunicadosRepositoryProvider).listar(apenasFixados: true, limit: 3));

final _ultimosComunicadosProvider = FutureProvider((ref) =>
    ref.watch(comunicadosRepositoryProvider).listar(limit: 5));

final _aniversariantesHojeProvider = FutureProvider<List<UserModel>>((ref) async {
  final todos = await ref.watch(usersRepositoryProvider).aniversariantesDoMes(DateTime.now().month);
  final hoje = DateTime.now().day;
  return todos.where((u) => u.dataNascimento!.day == hoje).toList();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final fixados = ref.watch(_fixadosProvider);
    final ultimos = ref.watch(_ultimosComunicadosProvider);
    final aniversariantes = ref.watch(_aniversariantesHojeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${user?.nomeCompleto.split(' ').first ?? ''} 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_fixadosProvider);
          ref.invalidate(_ultimosComunicadosProvider);
          ref.invalidate(_aniversariantesHojeProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _QuickActions(isAdmin: user?.isAdmin ?? false),
            const SizedBox(height: 24),

            // Aniversariantes do dia
            aniversariantes.when(
              data: (lista) => lista.isEmpty
                  ? const SizedBox.shrink()
                  : _SectionAniversariantes(lista: lista),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Comunicados fixados
            Text('📌 Fixados', style: AppTextStyles.title),
            const SizedBox(height: 8),
            fixados.when(
              data: (lista) => lista.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Nenhum comunicado fixado no momento.', style: AppTextStyles.bodyMuted),
                    )
                  : Column(children: lista.map((c) => _ComunicadoCard(comunicado: c)).toList()),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, __) => Text('Erro ao carregar: $e', style: AppTextStyles.bodyMuted),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Últimos comunicados', style: AppTextStyles.title),
                TextButton(
                  onPressed: () => context.go('/comunicados'),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            ultimos.when(
              data: (lista) => lista.isEmpty
                  ? const EmptyState(icon: Icons.campaign_outlined, title: 'Nenhum comunicado publicado ainda')
                  : Column(children: lista.map((c) => _ComunicadoCard(comunicado: c)).toList()),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, __) => Text('Erro ao carregar: $e', style: AppTextStyles.bodyMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool isAdmin;
  const _QuickActions({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionData>[
      _ActionData(Icons.campaign, 'Comunicados', () => context.go('/comunicados')),
      _ActionData(Icons.forum, 'Feed', () => context.go('/feed')),
      _ActionData(Icons.dialpad, 'Ramais', () => context.go('/ramais')),
      _ActionData(Icons.cake, 'Aniversários', () => context.go('/aniversariantes')),
      if (isAdmin) _ActionData(Icons.add_circle, 'Novo comunicado', () => context.go('/comunicados/novo')),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final a = actions[i];
          return InkWell(
            onTap: a.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 84,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(a.icon, color: AppColors.primary),
                  const SizedBox(height: 6),
                  Text(a.label, style: AppTextStyles.caption, textAlign: TextAlign.center, maxLines: 2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _ActionData(this.icon, this.label, this.onTap);
}

class _SectionAniversariantes extends StatelessWidget {
  final List<UserModel> lista;
  const _SectionAniversariantes({required this.lista});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        borderColor: AppColors.importante.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎂 Aniversariantes de hoje', style: AppTextStyles.title),
            const SizedBox(height: 12),
            ...lista.map((u) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: AppColors.surfaceAlt, child: Text(u.iniciais)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.nomeCompleto, style: AppTextStyles.body),
                            if (u.setor != null) Text(u.setor!, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ComunicadoCard extends StatelessWidget {
  final ComunicadoModel comunicado;
  const _ComunicadoCard({required this.comunicado});

  @override
  Widget build(BuildContext context) {
    final autorAdmin = comunicado.autor?.isAdmin ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => context.push('/comunicados/${comunicado.id}'),
        borderColor: autorAdmin ? AppColors.primary.withOpacity(0.25) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PriorityChip(prioridade: comunicado.prioridade),
                const SizedBox(width: 8),
                if (autorAdmin) const AdminBadge(compact: true),
                const Spacer(),
                Text(DateFormatters.tempoRelativo(comunicado.createdAt), style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            Text(comunicado.titulo, style: AppTextStyles.title),
            const SizedBox(height: 4),
            Text(
              comunicado.descricao,
              style: AppTextStyles.bodyMuted,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.favorite_border, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${comunicado.totalLikes}', style: AppTextStyles.caption),
                const SizedBox(width: 14),
                Icon(Icons.mode_comment_outlined, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${comunicado.totalComentarios}', style: AppTextStyles.caption),
                if (comunicado.exigeConfirmacao) ...[
                  const Spacer(),
                  Icon(
                    comunicado.confirmadoPeloUsuario ? Icons.check_circle : Icons.error_outline,
                    size: 15,
                    color: comunicado.confirmadoPeloUsuario ? AppColors.success : AppColors.obrigatorio,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    comunicado.confirmadoPeloUsuario ? 'Confirmado' : 'Confirmação pendente',
                    style: AppTextStyles.caption.copyWith(
                      color: comunicado.confirmadoPeloUsuario ? AppColors.success : AppColors.obrigatorio,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
