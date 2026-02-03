import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get usuarioAtual => _supabase.auth.currentUser;

  // =====================================================
  // CADASTRO (Mantive sua lógica de retornar String)
  // =====================================================
  Future<String?> cadastrarUsuario({
    required String email,
    required String password,
    required String nome,
    required String telefone,
    bool isAdmin = false,
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await _supabase.from('usuarios').insert({
          'id': res.user!.id,
          'email': email,
          'nome': nome,
          'telefone': telefone,
          'is_admin': isAdmin,
        });
      }
      return null;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('already exists')) {
        return 'Este e-mail já possui uma conta. Tente fazer login.';
      }
      if (msg.contains('password') && msg.contains('short')) {
        return 'A senha é muito curta.';
      }
      return 'Erro de autenticação: ${e.message}';
    } catch (e) {
      return "Erro desconhecido: $e";
    }
  }

  // =====================================================
  // LOGIN (Ajustado para void)
  // =====================================================
  // Alterei de Future<String?> para Future<void> pois não retornamos erro aqui,
  // deixamos ele "subir" para a tela tratar.
  Future<void> loginUsuario({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // =====================================================
  // RECUPERAÇÃO DE SENHA
  // =====================================================
  Future<String?> recuperarSenha({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://github.com/RiUza02/minaslar_aplicativo',
      );

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Erro desconhecido ao enviar e-mail.";
    }
  }

  // =====================================================
  // VERIFICAÇÃO DE PERMISSÃO
  // =====================================================
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

  // =====================================================
  // LOGOUT
  // =====================================================
  Future<void> deslogar() async {
    await _supabase.auth.signOut();
  }

  // =====================================================
  // VERIFICAÇÃO DE E-MAIL EXISTENTE
  // Usa uma função RPC no Supabase (opcional)
  // =====================================================
  Future<bool> verificarSeEmailExiste(String email) async {
    try {
      // Chama uma função SQL (RPC) chamada 'email_existe'
      final res = await _supabase.rpc(
        'email_existe',
        params: {'email_check': email},
      );

      return res as bool;
    } catch (e) {
      // Se a função não existir ou falhar,
      // deixamos o Supabase tratar duplicidade no cadastro
      return false;
    }
  }
}
