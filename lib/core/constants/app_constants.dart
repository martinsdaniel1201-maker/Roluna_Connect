import 'package:flutter/material.dart';
import 'app_colors.dart';

enum UserRole { admin, colaborador }

enum ComunicadoCategoria { rh, comercial, financeiro, logistica, estoque, diretoria, geral }

enum ComunicadoPrioridade { normal, importante, urgente, obrigatorio }

extension UserRoleX on UserRole {
  static UserRole fromString(String value) =>
      value == 'admin' ? UserRole.admin : UserRole.colaborador;

  String get asString => this == UserRole.admin ? 'admin' : 'colaborador';
}

extension CategoriaX on ComunicadoCategoria {
  static ComunicadoCategoria fromString(String value) {
    return ComunicadoCategoria.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ComunicadoCategoria.geral,
    );
  }

  String get label => switch (this) {
        ComunicadoCategoria.rh => 'RH',
        ComunicadoCategoria.comercial => 'Comercial',
        ComunicadoCategoria.financeiro => 'Financeiro',
        ComunicadoCategoria.logistica => 'Logística',
        ComunicadoCategoria.estoque => 'Estoque',
        ComunicadoCategoria.diretoria => 'Diretoria',
        ComunicadoCategoria.geral => 'Geral',
      };
}

extension PrioridadeX on ComunicadoPrioridade {
  static ComunicadoPrioridade fromString(String value) {
    return ComunicadoPrioridade.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ComunicadoPrioridade.normal,
    );
  }

  String get label => switch (this) {
        ComunicadoPrioridade.normal => 'Normal',
        ComunicadoPrioridade.importante => 'Importante',
        ComunicadoPrioridade.urgente => 'Urgente',
        ComunicadoPrioridade.obrigatorio => 'Obrigatório',
      };

  Color get color => switch (this) {
        ComunicadoPrioridade.normal => AppColors.normal,
        ComunicadoPrioridade.importante => AppColors.importante,
        ComunicadoPrioridade.urgente => AppColors.urgente,
        ComunicadoPrioridade.obrigatorio => AppColors.obrigatorio,
      };

  bool get exigeConfirmacao => this == ComunicadoPrioridade.obrigatorio;
}

class SupabaseConfig {
  // Projeto: roluna-connect (região sa-east-1)
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gvloqylqscbjqwypgpgm.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_LpvWJ1VNy-zrBILvEh0Y7Q_4-EpwdT-',
  );
}
