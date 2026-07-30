import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Selo visual que destaca publicações e comentários feitos por administradores.
class AdminBadge extends StatelessWidget {
  final bool compact;
  const AdminBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: AppColors.adminBadgeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.adminBadge.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: compact ? 11 : 13, color: AppColors.adminBadge),
          const SizedBox(width: 3),
          Text('ADMINISTRADOR', style: AppTextStyles.badge.copyWith(color: AppColors.adminBadge)),
        ],
      ),
    );
  }
}
