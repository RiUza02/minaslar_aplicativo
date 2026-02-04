import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get usuarioAtual => _supabase.auth.currentUser;

  // =====================================================
  // CADASTRO (OTIMIZADO COM TRIGGER)
  // =====================================================
  Future<String?> cadastrarUsuario({
    required String email,
    required String password,
    required String nome,
    required String telefone,
    bool isAdmin = false,
  }) async {
    try {
      // O "data" envia os dados extras.
      // A Trigger no banco vai ler isso e criar a linha na tabela 'usuarios' automaticamente.
      await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo:
            'https://riuza02.github.io/minaslar_aplicativo/VerificaEmail.html',
        data: {
          'nome': nome,
          'telefone': telefone,
          'isAdmin': isAdmin, // A Trigger lerá isso para definir a permissão
        },
      );

      // REMOVIDO: O insert manual na tabela 'usuarios'.
      // Motivo: Evita o risco de "usuário fantasma" se a internet cair aqui.

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
  // LOGIN
  // =====================================================
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
        redirectTo:
            'https://riuza02.github.io/minaslar_aplicativo/RecuperarEmail.html',
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Erro desconhecido ao enviar e-mail.";
    }
  }

  // =====================================================
  // VERIFICAÇÃO DE PERMISSÃO (SEM AWAIT / CACHE)
  // =====================================================
  // Alterei de Future<bool> para bool, pois agora é instantâneo!
  bool isUsuarioAdmin() {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    // Busca direto do Token (JWT), sem ir ao banco de dados.
    // Isso exige que a Trigger 'sync_admin_status' esteja rodando no banco.
    final metadata = user.appMetadata;

    return metadata['admin'] == true || metadata['role'] == 'admin';
  }

  // =====================================================
  // LOGOUT
  // =====================================================
  Future<void> deslogar() async {
    await _supabase.auth.signOut();
  }

  // =====================================================
  // VERIFICAÇÃO DE E-MAIL (RPC)
  // =====================================================
  Future<bool> verificarSeEmailExiste(String email) async {
    try {
      // Chama a função SQL 'email_existe' no banco de dados
      final res = await _supabase.rpc(
        'email_existe',
        params: {'email_check': email},
      );
      return res as bool;
    } catch (e) {
      // Se der erro (ex: função não existe no banco),
      // retornamos true para não travar o fluxo e deixar o Supabase tentar enviar.
      print('Erro ao verificar email: $e');
      return true;
    }
  }
}
