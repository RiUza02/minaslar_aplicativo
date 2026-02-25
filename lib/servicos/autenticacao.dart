import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/Usuario.dart';
import '../telas/criarConta/Login.dart';

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
      // PASSO 1: Verificar se o e-mail já existe usando a função RPC.
      // Esta função foi criada no seu painel do Supabase.
      final bool emailJaExiste = await _supabase.rpc(
        'email_exists',
        params: {'email_to_check': email},
      );

      if (emailJaExiste) {
        return 'EMAIL_JA_CADASTRADO';
      }

      // PASSO 2: Se o e-mail não existe, prosseguir com o cadastro.
      // O Trigger 'on_auth_user_created' no banco de dados irá usar os
      // metadados para criar a linha correspondente na tabela 'usuarios'.
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nome': nome,
          'telefone': telefone,
          // 'is_admin' não é enviado por segurança. O valor padrão no banco
          // de dados (trigger ou default da coluna) deve ser 'false'.
        },
      );

      return null; // Sucesso (null significa sem erro)
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Ocorreu um erro inesperado: $e";
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
      debugPrint('Erro ao buscar perfil do usuário: $e');
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
  // VERIFICAÇÃO DE STATUS DE ADMIN (ONLINE/OFFLINE)
  // =====================================================
  /// Verifica o status de admin do usuário de forma segura para online e offline.
  ///
  /// 1. Tenta buscar o perfil mais recente do servidor.
  /// 2. Se conseguir (online), atualiza o cache local e retorna o status.
  /// 3. Se não conseguir (offline), retorna o último status salvo no cache local.
  Future<bool> verificarStatusAdmin() async {
    // Tenta buscar os dados mais recentes do servidor.
    final usuarioProfile = await recuperarDadosUsuario();

    if (usuarioProfile != null) {
      // Se conseguiu (está online), atualizamos o cache local.
      await _salvarDadosLocais(usuarioProfile.isAdmin);
      return usuarioProfile.isAdmin;
    } else {
      // Se não conseguiu (offline), confiamos no último dado salvo localmente.
      return await isUsuarioAdminLocal();
    }
  }

  // =====================================================
  // VERIFICAÇÃO DE E-MAIL EXISTENTE (RPC)
  // =====================================================
  /// Verifica se um e-mail já está cadastrado na base `auth.users`.
  /// Retorna `true` se existir, `false` caso contrário.
  Future<bool> emailExiste(String email) async {
    try {
      final bool existe = await _supabase.rpc(
        'email_exists',
        params: {'email_to_check': email},
      );
      return existe;
    } catch (e) {
      debugPrint("Erro ao verificar existência do e-mail: $e");
      return false;
    }
  }

  // =====================================================
  // GERENCIAMENTO DE PERFIS DE USUÁRIO
  // =====================================================

  /// Busca todos os usuários cadastrados no sistema.
  Future<List<Usuario>> buscarTodosUsuarios() async {
    final response = await _supabase.from('usuarios').select().order('nome');
    final dados = response as List<dynamic>? ?? [];
    return dados.map((map) => Usuario.fromMap(map)).toList();
  }

  /// Atualiza os dados (nome e telefone) de um usuário específico.
  Future<void> atualizarPerfilUsuario({
    required String userId,
    required String nome,
    required String telefone,
  }) async {
    await _supabase
        .from('usuarios')
        .update({'nome': nome, 'telefone': telefone})
        .eq('id', userId);
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
    } on AuthException catch (e) {
      // O Supabase pode retornar 400 ou 403 para OTP inválido/expirado
      if (e.statusCode == "403" || e.statusCode == "400") {
        return "Código inválido ou expirado.";
      }
      return "Erro do servidor: $e";
    } catch (e) {
      // Captura qualquer outro erro que não seja do Supabase (ex: erro de rede bruto)
      return "Erro desconhecido: $e";
    }
  }
}

/// Tela exibida após o cadastro, solicitando a confirmação do e-mail
class VerificacaoEmail extends StatelessWidget {
  /// E-mail utilizado no cadastro
  final String email;

  const VerificacaoEmail({super.key, required this.email});

  // ============================================================
  // REALIZA LOGOUT E RETORNA PARA A TELA DE LOGIN
  // ============================================================
  Future<void> _voltarParaLogin(BuildContext context) async {
    // Força o logout para evitar que o AuthGate
    // redirecione automaticamente o usuário
    await AuthService().deslogar();

    if (context.mounted) {
      // Remove todas as rotas anteriores e abre a tela de login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmação Necessária"),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
        // Remove o botão de voltar para impedir navegação indevida
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Ícone ilustrativo de confirmação de e-mail
            const Icon(Icons.mark_email_unread, size: 100, color: Colors.blue),

            const SizedBox(height: 30),

            /// Título principal da tela
            const Text(
              "Verifique sua caixa de entrada",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            /// Texto explicativo sobre a confirmação
            Text(
              "Para sua segurança, saia do aplicativo e confirme o link que enviamos para:",
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            /// Destaque visual para o e-mail cadastrado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                email,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),

            /// Orientação final ao usuário
            const Text(
              "Após confirmar, volte aqui e faça login.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // ==================================================
            // AÇÃO ÚNICA: RETORNAR PARA O LOGIN
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _voltarParaLogin(context),
                child: const Text("Voltar para Tela de Login"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
