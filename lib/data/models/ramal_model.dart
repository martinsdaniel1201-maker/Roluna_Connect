class SetorModel {
  final String id;
  final String nome;
  final String? departamento;
  final List<RamalModel> ramais;

  const SetorModel({
    required this.id,
    required this.nome,
    this.departamento,
    this.ramais = const [],
  });
}

class RamalModel {
  final String id;
  final String nomeLocal;
  final String? responsavel;
  final String numero;

  const RamalModel({
    required this.id,
    required this.nomeLocal,
    this.responsavel,
    required this.numero,
  });

  factory RamalModel.fromJson(Map<String, dynamic> json) {
    return RamalModel(
      id: json['id'] as String,
      nomeLocal: json['nome_local'] as String,
      responsavel: json['responsavel'] as String?,
      numero: json['numero'] as String,
    );
  }
}
