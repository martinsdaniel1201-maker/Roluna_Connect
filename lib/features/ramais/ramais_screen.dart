import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/app_providers.dart';

final _ramaisAgrupadosProvider = FutureProvider((ref) => ref.watch(ramaisRepositoryProvider).listarAgrupado());

class RamaisScreen extends ConsumerWidget {
  const RamaisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setores = ref.watch(_ramaisAgrupadosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ramais internos')),
      body: setores.when(
        data: (lista) {
          if (lista.isEmpty) {
            return const EmptyState(icon: Icons.dialpad_outlined, title: 'Nenhum ramal cadastrado');
          }

          // Agrupa por departamento (ex: Administrativo, Comercial)
          final porDepartamento = <String, List<dynamic>>{};
          for (final setor in lista) {
            final dep = setor.departamento ?? 'Outros';
            porDepartamento.putIfAbsent(dep, () => []).add(setor);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: porDepartamento.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key, style: AppTextStyles.title.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: entry.value.expand<Widget>((setor) {
                          return setor.ramais.map<Widget>((r) => ListTile(
                                leading: const Icon(Icons.call_outlined, color: AppColors.accent),
                                title: Text(r.nomeLocal),
                                subtitle: r.responsavel != null ? Text(r.responsavel!) : null,
                                trailing: Text(
                                  r.numero,
                                  style: AppTextStyles.title.copyWith(color: AppColors.primary),
                                ),
                              ));
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Erro ao carregar ramais: $e')),
      ),
    );
  }
}
