import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get usuarioAtual => _supabase.auth.currentUser;

  // 1. CADASTRO (Cria Login + Salva dados na tabela usuarios)
  Future<String?> cadastrarUsuario({
    required String email,
    required String password,
    required String nome,
    required String telefone,
    bool isAdmin = false,
  }) async {
    try {
      // Cria o login na Auth do Supabase
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // Insere os dados extras na tabela 'usuarios'
        await _supabase.from('usuarios').insert({
          'id': res.user!.id, // Vincula com o Auth ID
          'email': email,
          'nome': nome,
          'telefone': telefone,
          'is_admin': isAdmin,
        });
      }
      return null; // Sucesso
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Erro desconhecido: $e";
    }
  }

  // RECUPERAR SENHA (SUPABASE)
  Future<String?> recuperarSenha({required String email}) async {
    try {
      // O Supabase envia um link mágico para o e-mail
      await _supabase.auth.resetPasswordForEmail(email);
      return null; // Sucesso
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Erro desconhecido ao enviar e-mail.";
    }
  }

  // 2. LOGIN
  Future<String?> loginUsuario({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Erro ao logar: $e";
    }
  }

  // 3. VERIFICAR SE É ADMIN
  Future<bool> isUsuarioAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final data = await _supabase
          .from('usuarios')
          .select('is_admin')
          .eq('id', user.id)
          .single();

      return data['is_admin'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> deslogar() async {
    await _supabase.auth.signOut();
  }
}
