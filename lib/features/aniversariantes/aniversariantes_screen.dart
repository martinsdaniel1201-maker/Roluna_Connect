import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/app_providers.dart';

final _mesSelecionadoProvider = StateProvider((ref) => DateTime.now().month);

final _aniversariantesProvider = FutureProvider((ref) {
  final mes = ref.watch(_mesSelecionadoProvider);
  return ref.watch(usersRepositoryProvider).aniversariantesDoMes(mes);
});

const _nomesMeses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

class AniversariantesScreen extends ConsumerWidget {
  const AniversariantesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(_mesSelecionadoProvider);
    final aniversariantes = ref.watch(_aniversariantesProvider);
    final hoje = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aniversariantes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 12,
              itemBuilder: (context, i) {
                final m = i + 1;
                final selecionado = m == mes;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: ChoiceChip(
                    label: Text(_nomesMeses[i].substring(0, 3)),
                    selected: selecionado,
                    onSelected: (_) => ref.read(_mesSelecionadoProvider.notifier).state = m,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: aniversariantes.when(
        data: (lista) {
          if (lista.isEmpty) {
            return EmptyState(
              icon: Icons.cake_outlined,
              title: 'Nenhum aniversariante em ${_nomesMeses[mes - 1]}',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final u = lista[i];
              final ehHoje = u.dataNascimento!.day == hoje.day && mes == hoje.month;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ehHoje ? AppColors.importante : AppColors.divider),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.surfaceAlt,
                      child: Text(u.iniciais, style: AppTextStyles.title),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.nomeCompleto, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                          if (u.setor != null) Text(u.setor!, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(DateFormatters.diaMes(u.dataNascimento!), style: AppTextStyles.title),
                        if (ehHoje)
                          Text('Hoje 🎉', style: AppTextStyles.caption.copyWith(color: AppColors.importante)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Erro ao carregar aniversariantes: $e')),
      ),
    );
  }
}
