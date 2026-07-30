import 'user_model.dart';

class PostModel {
  final String id;
  final UserModel autor;
  final String texto;
  final String? anexoUrl;
  final String? anexoTipo; // 'imagem' | 'pdf'
  final DateTime publicarEm;
  final DateTime createdAt;
  final int totalLikes;
  final int totalComentarios;
  final bool curtidoPeloUsuario;

  const PostModel({
    required this.id,
    required this.autor,
    required this.texto,
    this.anexoUrl,
    this.anexoTipo,
    required this.publicarEm,
    required this.createdAt,
    this.totalLikes = 0,
    this.totalComentarios = 0,
    this.curtidoPeloUsuario = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      autor: UserModel.fromJson(json['autor'] as Map<String, dynamic>),
      texto: json['texto'] as String,
      anexoUrl: json['anexo_url'] as String?,
      anexoTipo: json['anexo_tipo'] as String?,
      publicarEm: DateTime.parse(json['publicar_em'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      totalLikes: json['total_likes'] as int? ?? 0,
      totalComentarios: json['total_comentarios'] as int? ?? 0,
      curtidoPeloUsuario: json['curtido_pelo_usuario'] as bool? ?? false,
    );
  }
}
