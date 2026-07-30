import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../providers/app_providers.dart';

final _dashboardProvider = FutureProvider((ref) => ref.watch(statsRepositoryProvider).dashboard());
final _obrigatoriosStatsProvider =
    FutureProvider((ref) => ref.watch(statsRepositoryProvider).comunicadosObrigatoriosStats());

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(_dashboardProvider);
    final obrigatorios = ref.watch(_obrigatoriosStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Painel administrativo')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_dashboardProvider);
          ref.invalidate(_obrigatoriosStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            dashboard.when(
              data: (d) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    icon: Icons.people_outline,
                    label: 'Colaboradores',
                    valor: '${d['total_colaboradores']}',
                    cor: AppColors.primary,
                  ),
                  _StatCard(
                    icon: Icons.campaign_outlined,
                    label: 'Comunicados publicados',
                    valor: '${d['total_comunicados']}',
                    cor: AppColors.accent,
                  ),
                  _StatCard(
                    icon: Icons.error_outline,
                    label: 'Obrigatórios ativos',
                    valor: '${d['total_obrigatorios']}',
                    cor: AppColors.obrigatorio,
                  ),
                  _StatCard(
                    icon: Icons.forum_outlined,
                    label: 'Publicações hoje',
                    valor: '${d['posts_hoje']}',
                    cor: AppColors.success,
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, __) => Text('Erro ao carregar dashboard: $e'),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Comunicados obrigatórios', style: AppTextStyles.title),
                TextButton.icon(
                  onPressed: () => context.push('/comunicados/novo'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Novo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            obrigatorios.when(
              data: (lista) {
                if (lista.isEmpty) {
                  return Text('Nenhum comunicado obrigatório ativo.', style: AppTextStyles.bodyMuted);
                }
                return Column(
                  children: lista.map((item) {
                    final total = item['total_colaboradores'] as int? ?? 0;
                    final confirmados = item['total_confirmados'] as int? ?? 0;
                    final percentual = total == 0 ? 0.0 : confirmados / total;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        onTap: () => context.push('/comunicados/${item['comunicado_id']}/confirmacoes'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['titulo'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: percentual,
                                minHeight: 8,
                                backgroundColor: AppColors.surfaceAlt,
                                valueColor: const AlwaysStoppedAnimation(AppColors.success),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('$confirmados de $total confirmaram (${(percentual * 100).toStringAsFixed(0)}%)',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Text('Erro: $e'),
            ),
            const SizedBox(height: 28),
            Text('Gerenciamento', style: AppTextStyles.title),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.group_outlined, color: AppColors.primary),
                    title: const Text('Gerenciar colaboradores'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.dialpad_outlined, color: AppColors.primary),
                    title: const Text('Gerenciar ramais'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final Color cor;
  const _StatCard({required this.icon, required this.label, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cor),
          const Spacer(),
          Text(valor, style: AppTextStyles.displayLarge.copyWith(fontSize: 24)),
          Text(label, style: AppTextStyles.caption, maxLines: 2),
        ],
      ),
    );
  }
}
