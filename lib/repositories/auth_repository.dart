import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client_provider.dart';
import '../data/models/user_model.dart';

class AuthRepository {
  final SupabaseClient _client = supabase;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentAuthUser => _client.auth.currentUser;

  bool get isLoggedIn => currentAuthUser != null;

  Future<void> signIn({required String email, required String senha}) async {
    await _client.auth.signInWithPassword(email: email, password: senha);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Busca o profile completo (com role) do usuário autenticado.
  Future<UserModel> fetchCurrentProfile() async {
    final uid = currentAuthUser!.id;
    final data = await _client.from('profiles').select().eq('id', uid).single();
    return UserModel.fromJson(data);
  }
}
