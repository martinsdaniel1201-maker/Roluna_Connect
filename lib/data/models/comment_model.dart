import 'user_model.dart';

class CommentModel {
  final String id;
  final UserModel autor;
  final String texto;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.autor,
    required this.texto,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      autor: UserModel.fromJson(json['autor'] as Map<String, dynamic>),
      texto: json['texto'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
