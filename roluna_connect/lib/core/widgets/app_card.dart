import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Card padrão do app: cantos arredondados, sombra suave, fundo branco.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor ?? AppColors.divider),
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
