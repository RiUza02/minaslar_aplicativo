import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/Usuario.dart'; // Certifique-se que o caminho está certo

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get usuarioAtual => _supabase.auth.currentUser;

  // =====================================================
  // LOGIN
  // =====================================================
  Future<void> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthException('Erro ao realizar login: Usuário nulo.');
      }

      // --- ATUALIZAÇÃO IMPORTANTE ---
      // Após o login, buscamos o perfil na tabela 'public.usuarios'
      // para ter certeza se ele é admin ou não.
      final usuarioProfile = await recuperarDadosUsuario();
      final bool isAdmin = usuarioProfile?.isAdmin ?? false;

      await _salvarDadosLocais(isAdmin);
    } catch (e) {
      rethrow; // Repassa o erro para a tela tratar (exibir SnackBar)
    }
  }

  // =====================================================
  // CADASTRO
  // =====================================================
  Future<String?> cadastrarUsuario({
    required String email,
    required String password,
    required String nome,
    required String telefone,
    required bool isAdmin,
  }) async {
    try {
      // O Trigger 'on_auth_user_created' no Banco vai pegar esses dados
      // e criar a linha na tabela 'usuarios' automaticamente.
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nome': nome, // Vai para: new.raw_user_meta_data ->> 'nome'
          'telefone':
              telefone, // Vai para: new.raw_user_meta_data ->> 'telefone'
          // OBS: Não enviamos 'is_admin' aqui por segurança.
          // O banco define padrão como FALSE.
        },
      );

      return null; // Sucesso (null significa sem erro)
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Erro desconhecido: $e";
    }
  }

  // =====================================================
  // RECUPERAR DADOS DO PERFIL (Tabela 'usuarios')
  // =====================================================
  Future<Usuario?> recuperarDadosUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('usuarios') // Nome da tabela no Supabase
          .select()
          .eq('id', user.id)
          .single();

      return Usuario.fromMap(data);
    } catch (e) {
      print('Erro ao buscar perfil do usuário: $e');
      return null;
    }
  }

  // =====================================================
  // CACHE LOCAL (SharedPreferences)
  // =====================================================
  Future<void> _salvarDadosLocais(bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('IS_ADMIN', isAdmin);
  }

  Future<void> _limparDadosLocais() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('IS_ADMIN');
  }

  Future<bool> isUsuarioAdminLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('IS_ADMIN') ?? false;
  }

  // =====================================================
  // LOGOUT
  // =====================================================
  Future<void> deslogar() async {
    await _limparDadosLocais();
    await _supabase.auth.signOut();
  }

  // =====================================================
  // RECUPERAÇÃO DE SENHA (FLUXO COMPLETO)
  // =====================================================

  /// Passo 1: Envia o código (Token) por e-mail
  Future<String?> enviarTokenRecuperacao(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        // Se quiser usar Link Mágico, mude para: emailRedirectTo: '...'
        // Se quiser usar Código (Token), deixe assim.
      );
      return null;
    } catch (e) {
      return "Erro ao enviar código: $e";
    }
  }

  /// Passo 2: Valida o código e troca a senha
  Future<String?> validarTokenEAtualizarSenha(
    String email,
    String token,
    String novaSenha,
  ) async {
    try {
      // Verifica o código de 6 dígitos
      final res = await _supabase.auth.verifyOTP(
        token: token,
        type: OtpType.email,
        email: email,
      );

      if (res.session == null) return "Código inválido ou expirado.";

      // Se verificou com sucesso, o usuário está logado. Agora trocamos a senha.
      await _supabase.auth.updateUser(UserAttributes(password: novaSenha));

      return null; // Sucesso
    } catch (e) {
      return "Erro ao atualizar senha: $e";
    }
  }

  // Opcional: Verifica se o e-mail já existe (Requer RPC no banco)
  Future<bool> verificarSeEmailExiste(String email) async {
    try {
      final res = await _supabase.rpc(
        'email_existe', // Nome da função criada no SQL do Supabase
        params: {'email_check': email},
      );
      return res as bool;
    } catch (e) {
      // Se a função RPC não existir ou der erro, assumimos false para não travar
      return false;
    }
  }
}
