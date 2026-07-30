import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/comunicado_model.dart';
import '../../providers/app_providers.dart';

class ComunicadoFormScreen extends ConsumerStatefulWidget {
  const ComunicadoFormScreen({super.key});

  @override
  ConsumerState<ComunicadoFormScreen> createState() => _ComunicadoFormScreenState();
}

class _ComunicadoFormScreenState extends ConsumerState<ComunicadoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();

  ComunicadoCategoria _categoria = ComunicadoCategoria.geral;
  ComunicadoPrioridade _prioridade = ComunicadoPrioridade.normal;
  bool _fixado = false;
  DateTime? _agendarPara;
  bool _salvando = false;

  Future<void> _selecionarAgendamento() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (data == null || !mounted) return;
    final hora = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (hora == null) return;
    setState(() {
      _agendarPara = DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('Usuário não autenticado');

      final comunicado = ComunicadoModel(
        id: '',
        titulo: _tituloCtrl.text.trim(),
        descricao: _descricaoCtrl.text.trim(),
        autor: null,
        categoria: _categoria,
        prioridade: _prioridade,
        fixado: _fixado,
        publicarEm: _agendarPara ?? DateTime.now(),
        createdAt: DateTime.now(),
      );

      await ref.read(comunicadosRepositoryProvider).criar(comunicado, user.id);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao publicar: $e')));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo comunicado')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o título' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descricaoCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 6,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
            ),
            const SizedBox(height: 18),
            Text('Categoria', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ComunicadoCategoria.values.map((c) {
                return ChoiceChip(
                  label: Text(c.label),
                  selected: _categoria == c,
                  onSelected: (_) => setState(() => _categoria = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text('Prioridade', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ComunicadoPrioridade.values.map((p) {
                return ChoiceChip(
                  label: Text(p.label),
                  selected: _prioridade == p,
                  selectedColor: p.color.withOpacity(0.2),
                  onSelected: (_) => setState(() => _prioridade = p),
                );
              }).toList(),
            ),
            if (_prioridade == ComunicadoPrioridade.obrigatorio) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.obrigatorio.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.obrigatorio),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Os colaboradores precisarão confirmar a leitura com o botão "Li e estou ciente".',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fixar no topo'),
              subtitle: const Text('Aparece em destaque na Home'),
              value: _fixado,
              onChanged: (v) => setState(() => _fixado = v),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(_agendarPara == null ? 'Publicar agora' : 'Agendado'),
              subtitle: _agendarPara != null
                  ? Text('${_agendarPara!.day}/${_agendarPara!.month}/${_agendarPara!.year} às '
                      '${_agendarPara!.hour.toString().padLeft(2, '0')}:${_agendarPara!.minute.toString().padLeft(2, '0')}')
                  : const Text('Toque para agendar data e hora'),
              trailing: _agendarPara != null
                  ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _agendarPara = null))
                  : null,
              onTap: _selecionarAgendamento,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_agendarPara == null ? 'Publicar comunicado' : 'Agendar comunicado'),
            ),
          ],
        ),
      ),
    );
  }
}
