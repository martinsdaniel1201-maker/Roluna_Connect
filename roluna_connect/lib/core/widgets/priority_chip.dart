import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/app_text_styles.dart';

class PriorityChip extends StatelessWidget {
  final ComunicadoPrioridade prioridade;
  const PriorityChip({super.key, required this.prioridade});

  @override
  Widget build(BuildContext context) {
    final cor = prioridade.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prioridade == ComunicadoPrioridade.obrigatorio) ...[
            Icon(Icons.priority_high, size: 12, color: cor),
            const SizedBox(width: 2),
          ],
          Text(prioridade.label.toUpperCase(), style: AppTextStyles.badge.copyWith(color: cor)),
        ],
      ),
    );
  }
}
