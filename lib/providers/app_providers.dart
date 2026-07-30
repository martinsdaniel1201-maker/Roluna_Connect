import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/comunicados_repository.dart';
import '../repositories/feed_repository.dart';
import '../repositories/ramais_repository.dart';
import '../repositories/users_repository.dart';
import '../repositories/stats_repository.dart';

// ---- Repositories (singletons simples) ------------------------------------
final authRepositoryProvider = Provider((ref) => AuthRepository());
final comunicadosRepositoryProvider = Provider((ref) => ComunicadosRepository());
final feedRepositoryProvider = Provider((ref) => FeedRepository());
final ramaisRepositoryProvider = Provider((ref) => RamaisRepository());
final usersRepositoryProvider = Provider((ref) => UsersRepository());
final statsRepositoryProvider = Provider((ref) => StatsRepository());

// ---- Sessão / usuário atual -------------------------------------------------

/// Stream de mudanças de autenticação (login/logout).
final authStateProvider = StreamProvider((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Perfil completo do usuário logado (com role admin/colaborador).
/// Refaz automaticamente quando o estado de auth muda.
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final repo = ref.watch(authRepositoryProvider);

  return authState.when(
    data: (_) async {
      if (!repo.isLoggedIn) return null;
      return repo.fetchCurrentProfile();
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Atalho síncrono e conveniente para checar se o usuário é admin em widgets.
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.isAdmin ?? false;
});
