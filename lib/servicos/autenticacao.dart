import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço responsável por autenticação
/// e controle de sessão usando Supabase
class AuthService {
  /// Cliente principal do Supabase
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Retorna o usuário atualmente autenticado
  /// (null se não estiver logado)
  User? get usuarioAtual => _supabase.auth.currentUser;

  // =====================================================
  // CADASTRO DE USUÁRIO
  // Cria o login no Auth e salva dados na tabela 'usuarios'
  // =====================================================
  Future<String?> cadastrarUsuario({
    required String email,
    required String password,
    required String nome,
    required String telefone,
    bool isAdmin = false,
  }) async {
    try {
      // Cria o usuário no sistema de autenticação do Supabase
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // Se o usuário foi criado com sucesso
      if (res.user != null) {
        // Salva os dados complementares
        // na tabela personalizada 'usuarios'
        await _supabase.from('usuarios').insert({
          // O ID deve ser o mesmo do Auth
          'id': res.user!.id,
          'email': email,
          'nome': nome,
          'telefone': telefone,

          // Coluna em snake_case no banco
          'is_admin': isAdmin,
        });
      }

      // Retorna null indicando sucesso
      return null;
    } on AuthException catch (e) {
      // Erros tratados pelo Supabase (ex: e-mail já cadastrado)
      return e.message;
    } catch (e) {
      // Qualquer outro erro inesperado
      return "Erro desconhecido: $e";
    }
  }

  // =====================================================
  // RECUPERAÇÃO DE SENHA
  // Envia link de redefinição por e-mail
  // =====================================================
  Future<String?> recuperarSenha({required String email}) async {
    try {
      // Supabase envia um e-mail com link de redefinição
      await _supabase.auth.resetPasswordForEmail(email);
      return null; // Sucesso
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Erro desconhecido ao enviar e-mail.";
    }
  }

  // =====================================================
  // LOGIN DO USUÁRIO
  // Autenticação usando e-mail e senha
  // =====================================================
  Future<String?> loginUsuario({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return null; // Login realizado
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Erro ao logar: $e";
    }
  }

  // =====================================================
  // VERIFICAÇÃO DE PERMISSÃO
  // Retorna true se o usuário for administrador
  // =====================================================
  Future<bool> isUsuarioAdmin() async {
    final user = _supabase.auth.currentUser;

    // Se não estiver logado, não é admin
    if (user == null) return false;

    try {
      // Busca o campo is_admin na tabela 'usuarios'
      final data = await _supabase
          .from('usuarios')
          .select('is_admin')
          .eq('id', user.id)
          .single();

      return data['is_admin'] ?? false;
    } catch (e) {
      // Em caso de erro, assume que não é admin
      return false;
    }
  }

  // =====================================================
  // LOGOUT
  // Encerra a sessão atual
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
