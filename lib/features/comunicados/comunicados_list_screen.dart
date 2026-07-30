import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/app_providers.dart';

final _categoriaFiltroProvider = StateProvider<ComunicadoCategoria?>((ref) => null);

final _comunicadosListProvider = FutureProvider((ref) {
  final categoria = ref.watch(_categoriaFiltroProvider);
  return ref.watch(comunicadosRepositoryProvider).listar(categoria: categoria?.name, limit: 50);
});

class ComunicadosListScreen extends ConsumerWidget {
  const ComunicadosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final categoriaAtiva = ref.watch(_categoriaFiltroProvider);
    final comunicados = ref.watch(_comunicadosListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Comunicados')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/comunicados/novo'),
              icon: const Icon(Icons.add),
              label: const Text('Novo comunicado'),
            )
          : null,
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FiltroChip(
                  label: 'Todos',
                  selected: categoriaAtiva == null,
                  onTap: () => ref.read(_categoriaFiltroProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                ...ComunicadoCategoria.values.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FiltroChip(
                        label: c.label,
                        selected: categoriaAtiva == c,
                        onTap: () => ref.read(_categoriaFiltroProvider.notifier).state = c,
                      ),
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: comunicados.when(
              data: (lista) {
                if (lista.isEmpty) {
                  return const EmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'Nenhum comunicado encontrado',
                    subtitle: 'Tente outra categoria ou volte mais tarde.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(_comunicadosListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final c = lista[i];
                      return ListTile(
                        tileColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.divider),
                        ),
                        leading: Icon(
                          c.fixado ? Icons.push_pin : Icons.campaign_outlined,
                          color: c.prioridade.color,
                        ),
                        title: Text(c.titulo, style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(c.categoria.label, style: AppTextStyles.caption),
                        trailing: c.exigeConfirmacao
                            ? Icon(
                                c.confirmadoPeloUsuario ? Icons.check_circle : Icons.error_outline,
                                color: c.confirmadoPeloUsuario ? AppColors.success : AppColors.obrigatorio,
                                size: 20,
                              )
                            : null,
                        onTap: () => context.push('/comunicados/${c.id}'),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Erro ao carregar comunicados: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FiltroChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: AppTextStyles.caption.copyWith(color: selected ? Colors.white : AppColors.textPrimary),
      backgroundColor: AppColors.surfaceAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }
}
