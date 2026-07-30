import '../../core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String nomeCompleto;
  final String email;
  final String? cargo;
  final String? setor;
  final String? ramal;
  final String? telefone;
  final String? fotoUrl;
  final DateTime? dataNascimento;
  final UserRole role;
  final bool ativo;

  const UserModel({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    this.cargo,
    this.setor,
    this.ramal,
    this.telefone,
    this.fotoUrl,
    this.dataNascimento,
    this.role = UserRole.colaborador,
    this.ativo = true,
  });

  bool get isAdmin => role == UserRole.admin;

  String get iniciais {
    final partes = nomeCompleto.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nomeCompleto: json['nome_completo'] as String? ?? 'Sem nome',
      email: json['email'] as String? ?? '',
      cargo: json['cargo'] as String?,
      setor: json['setor'] as String?,
      ramal: json['ramal'] as String?,
      telefone: json['telefone'] as String?,
      fotoUrl: json['foto_url'] as String?,
      dataNascimento: json['data_nascimento'] != null
          ? DateTime.tryParse(json['data_nascimento'] as String)
          : null,
      role: UserRoleX.fromString(json['role'] as String? ?? 'colaborador'),
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome_completo': nomeCompleto,
        'email': email,
        'cargo': cargo,
        'setor': setor,
        'ramal': ramal,
        'telefone': telefone,
        'foto_url': fotoUrl,
        'data_nascimento': dataNascimento?.toIso8601String(),
        'role': role.asString,
        'ativo': ativo,
      };
}
