import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/app_providers.dart';
import '../../data/models/user_model.dart';

final _statsProvider = FutureProvider.family(
  (ref, String comunicadoId) => ref.watch(comunicadosRepositoryProvider).estatisticasLeitura(comunicadoId),
);

final _confirmacoesProvider = FutureProvider.family(
  (ref, String comunicadoId) => ref.watch(comunicadosRepositoryProvider).listarConfirmacoes(comunicadoId),
);

final _todosColaboradoresProvider = FutureProvider((ref) => ref.watch(usersRepositoryProvider).listarTodos());

class ConfirmacoesScreen extends ConsumerWidget {
  final String comunicadoId;
  const ConfirmacoesScreen({super.key, required this.comunicadoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(_statsProvider(comunicadoId));
    final confirmacoes = ref.watch(_confirmacoesProvider(comunicadoId));
    final todos = ref.watch(_todosColaboradoresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmações de leitura')),
      body: stats.when(
        data: (s) {
          final percentual = (s['percentual'] as double) * 100;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${percentual.toStringAsFixed(0)}% confirmaram a leitura',
                        style: AppTextStyles.headline),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: s['percentual'] as double,
                        minHeight: 10,
                        backgroundColor: AppColors.surfaceAlt,
                        valueColor: const AlwaysStoppedAnimation(AppColors.success),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MiniStat(label: 'Total', valor: '${s['total_colaboradores']}'),
                        _MiniStat(label: 'Confirmaram', valor: '${s['total_confirmados']}', cor: AppColors.success),
                        _MiniStat(label: 'Pendentes', valor: '${s['pendentes']}', cor: AppColors.obrigatorio),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Confirmaram', style: AppTextStyles.title),
              const SizedBox(height: 8),
              confirmacoes.when(
                data: (lista) => lista.isEmpty
                    ? Text('Ninguém confirmou ainda.', style: AppTextStyles.bodyMuted)
                    : Column(
                        children: lista
                            .map((c) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.success.withOpacity(0.15),
                                    child: Icon(Icons.check, color: AppColors.success, size: 18),
                                  ),
                                  title: Text(c.usuario.nomeCompleto),
                                  subtitle: Text(c.usuario.setor ?? ''),
                                  trailing: Text(
                                    DateFormatters.dataHora(c.confirmadoEm),
                                    style: AppTextStyles.caption,
                                  ),
                                ))
                            .toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => Text('Erro: $e'),
              ),
              const SizedBox(height: 24),
              Text('Pendentes', style: AppTextStyles.title),
              const SizedBox(height: 8),
              confirmacoes.when(
                data: (confirmadosLista) {
                  final confirmadosIds = confirmadosLista.map((c) => c.usuario.id).toSet();
                  return todos.when(
                    data: (todosColaboradores) {
                      final pendentes =
                          todosColaboradores.where((u) => !confirmadosIds.contains(u.id)).toList();
                      if (pendentes.isEmpty) {
                        return const EmptyState(
                          icon: Icons.celebration_outlined,
                          title: 'Todos confirmaram!',
                        );
                      }
                      return Column(
                        children: pendentes.map((u) => _PendenteTile(usuario: u)).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, __) => Text('Erro: $e'),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Erro ao carregar estatísticas: $e')),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String valor;
  final Color? cor;
  const _MiniStat({required this.label, required this.valor, this.cor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor, style: AppTextStyles.headline.copyWith(color: cor ?? AppColors.textPrimary)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _PendenteTile extends StatelessWidget {
  final UserModel usuario;
  const _PendenteTile({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.obrigatorio.withOpacity(0.12),
        child: Text(usuario.iniciais, style: TextStyle(color: AppColors.obrigatorio, fontSize: 12)),
      ),
      title: Text(usuario.nomeCompleto),
      subtitle: Text(usuario.setor ?? ''),
      trailing: const Icon(Icons.schedule, size: 18, color: AppColors.obrigatorio),
    );
  }
}
