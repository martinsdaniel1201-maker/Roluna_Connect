import 'user_model.dart';

class ConfirmacaoModel {
  final String id;
  final String comunicadoId;
  final UserModel usuario;
  final DateTime confirmadoEm;

  const ConfirmacaoModel({
    required this.id,
    required this.comunicadoId,
    required this.usuario,
    required this.confirmadoEm,
  });

  factory ConfirmacaoModel.fromJson(Map<String, dynamic> json) {
    return ConfirmacaoModel(
      id: json['id'] as String,
      comunicadoId: json['comunicado_id'] as String,
      usuario: UserModel.fromJson(json['usuario'] as Map<String, dynamic>),
      confirmadoEm: DateTime.parse(json['confirmado_em'] as String),
    );
  }
}
