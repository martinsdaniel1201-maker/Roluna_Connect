import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/comunicados/comunicados_list_screen.dart';
import '../../features/comunicados/comunicado_detail_screen.dart';
import '../../features/comunicados/comunicado_form_screen.dart';
import '../../features/comunicados/confirmacoes_screen.dart';
import '../../features/feed/feed_screen.dart';
import '../../features/ramais/ramais_screen.dart';
import '../../features/aniversariantes/aniversariantes_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../providers/app_providers.dart';

/// Ordem das abas principais — usada pelo MainShell para destacar o item ativo.
const _abasPrincipais = ['/home', '/comunicados', '/feed', '/ramais', '/admin'];

/// Provider único do GoRouter — garante que o mesmo router (e seu estado
/// de navegação) sobrevive a rebuilds do widget tree.
final appRouterProvider = Provider<GoRouter>((ref) => AppRouter.build(ref));

class AppRouter {
  static GoRouter build(Ref ref) {
    return GoRouter(
      initialLocation: '/home',
      refreshListenable: _GoRouterRefreshStream(ref),
      redirect: (context, state) {
        final isLoggedIn = ref.read(authRepositoryProvider).isLoggedIn;
        final indoParaLogin = state.matchedLocation == '/login';

        if (!isLoggedIn && !indoParaLogin) return '/login';
        if (isLoggedIn && indoParaLogin) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

        // Rotas de detalhe/formulário abrem por cima do shell (push), preservando a bottom nav.
        GoRoute(
          path: '/comunicados/novo',
          builder: (context, state) => const ComunicadoFormScreen(),
        ),
        GoRoute(
          path: '/comunicados/:id',
          builder: (context, state) =>
              ComunicadoDetailScreen(comunicadoId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/comunicados/:id/confirmacoes',
          builder: (context, state) =>
              ConfirmacoesScreen(comunicadoId: state.pathParameters['id']!),
        ),

        // Shell com bottom navigation para as seções principais.
        ShellRoute(
          builder: (context, state, child) {
            final index = _abasPrincipais.indexWhere((p) => state.matchedLocation.startsWith(p));
            return MainShell(
              currentIndex: index < 0 ? 0 : index,
              onTap: (i) => context.go(_abasPrincipais[i]),
              child: child,
            );
          },
          routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            GoRoute(path: '/comunicados', builder: (context, state) => const ComunicadosListScreen()),
            GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
            GoRoute(path: '/ramais', builder: (context, state) => const RamaisScreen()),
            GoRoute(path: '/aniversariantes', builder: (context, state) => const AniversariantesScreen()),
            GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),
          ],
        ),
      ],
    );
  }
}

/// Faz o GoRouter reavaliar o redirect sempre que o estado de autenticação mudar.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
