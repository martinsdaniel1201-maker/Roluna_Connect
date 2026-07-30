import '../../core/constants/app_constants.dart';
import 'user_model.dart';

class ComunicadoModel {
  final String id;
  final String titulo;
  final String descricao;
  final UserModel? autor;
  final ComunicadoCategoria categoria;
  final ComunicadoPrioridade prioridade;
  final bool fixado;
  final String? anexoUrl;
  final DateTime publicarEm;
  final DateTime createdAt;

  // Campos calculados (via joins/queries agregadas)
  final int totalLikes;
  final int totalComentarios;
  final bool curtidoPeloUsuario;
  final bool confirmadoPeloUsuario;
  final int? totalColaboradores;
  final int? totalConfirmados;

  const ComunicadoModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.autor,
    required this.categoria,
    required this.prioridade,
    required this.fixado,
    this.anexoUrl,
    required this.publicarEm,
    required this.createdAt,
    this.totalLikes = 0,
    this.totalComentarios = 0,
    this.curtidoPeloUsuario = false,
    this.confirmadoPeloUsuario = false,
    this.totalColaboradores,
    this.totalConfirmados,
  });

  bool get exigeConfirmacao => prioridade.exigeConfirmacao;

  double get percentualLeitura {
    if (totalColaboradores == null || totalColaboradores == 0) return 0;
    return (totalConfirmados ?? 0) / totalColaboradores!;
  }

  factory ComunicadoModel.fromJson(Map<String, dynamic> json) {
    return ComunicadoModel(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String,
      autor: json['autor'] != null ? UserModel.fromJson(json['autor'] as Map<String, dynamic>) : null,
      categoria: CategoriaX.fromString(json['categoria'] as String? ?? 'geral'),
      prioridade: PrioridadeX.fromString(json['prioridade'] as String? ?? 'normal'),
      fixado: json['fixado'] as bool? ?? false,
      anexoUrl: json['anexo_url'] as String?,
      publicarEm: DateTime.parse(json['publicar_em'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      totalLikes: json['total_likes'] as int? ?? 0,
      totalComentarios: json['total_comentarios'] as int? ?? 0,
      curtidoPeloUsuario: json['curtido_pelo_usuario'] as bool? ?? false,
      confirmadoPeloUsuario: json['confirmado_pelo_usuario'] as bool? ?? false,
      totalColaboradores: json['total_colaboradores'] as int?,
      totalConfirmados: json['total_confirmados'] as int?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'titulo': titulo,
        'descricao': descricao,
        'categoria': categoria.name,
        'prioridade': prioridade.name,
        'fixado': fixado,
        'obrigatorio': prioridade == ComunicadoPrioridade.obrigatorio,
        'anexo_url': anexoUrl,
        'publicar_em': publicarEm.toIso8601String(),
      };
}
