import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/Usuario.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get usuarioAtual => _supabase.auth.currentUser;

  // =====================================================
  // LOGIN
  // =====================================================
  Future<void> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw const AuthException('Erro ao realizar login.');
    }

    final appMetadata = response.user!.appMetadata;
    final userMetadata = response.user!.userMetadata;

    final bool isAdmin =
        (appMetadata['role'] == 'admin') ||
        (appMetadata['is_admin'] == true) ||
        (userMetadata?['is_admin'] == true);

    await _salvarDadosLocais(isAdmin);
  }

  // =====================================================
  // CADASTRO (Lógica Limpa)
  // =====================================================
  // =====================================================
  // CADASTRO (Versão Corrigida)
  // =====================================================
  Future<String?> cadastrarUsuario({
    required String email,
    required String password,
    required String nome,
    required String telefone,
    bool isAdmin = false,
  }) async {
    try {
      // 1. Sanitização (Limpeza) dos dados
      // Remove tudo que não for número do telefone para evitar erros no banco
      final telefoneLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');

      print("📤 Enviando cadastro...");
      print("Dados: Nome=$nome, Tel=$telefoneLimpo, Admin=$isAdmin");

      // 2. Chamada ao Supabase
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nome': nome,
          'telefone': telefoneLimpo, // Envia limpo: "32999999999"
          'is_admin': isAdmin, // Envia boolean real: true/false
        },
      );

      print("✅ Cadastro realizado no Auth com sucesso!");
      return null; // Sucesso
    } on AuthException catch (e) {
      print("❌ Erro de Auth: ${e.message} (Code: ${e.statusCode})");

      // Tratamento de erros conhecidos
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('unique constraint') ||
          e.statusCode == '422') {
        return 'EMAIL_JA_CADASTRADO';
      }
      return e.message;
    } catch (e) {
      print("❌ Erro Genérico/Decode: $e");

      // Se o erro for de decodificação, geralmente é porque o servidor
      // respondeu com algo que não é JSON (crash do trigger ou timeout).
      // Mas como já arrumamos o trigger, deve ser apenas instabilidade.
      final msg = e.toString().toLowerCase();
      if (msg.contains('23505') || msg.contains('duplicate')) {
        return 'EMAIL_JA_CADASTRADO';
      }
      return "Erro de conexão ou servidor. Tente novamente.";
    }
  }

  // =====================================================
  // CACHE LOCAL (Persistência, não UI)
  // =====================================================
  Future<void> _salvarDadosLocais(bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('IS_ADMIN', isAdmin);
  }

  Future<void> _limparDadosLocais() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('IS_ADMIN');
  }

  // =====================================================
  // OUTROS MÉTODOS
  // =====================================================
  Future<void> deslogar() async {
    await _limparDadosLocais();
    await _supabase.auth.signOut();
  }

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
      return "Erro ao enviar e-mail.";
    }
  }

  // Apenas lógica booleana, sem UI
  bool isUsuarioAdmin() {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    final appMetadata = user.appMetadata;
    final userMetadata = user.userMetadata;
    return (appMetadata['role'] == 'admin') ||
        (appMetadata['is_admin'] == true) ||
        (userMetadata?['is_admin'] == true);
  }

  Future<bool> verificarSeEmailExiste(String email) async {
    try {
      final res = await _supabase.rpc(
        'email_existe',
        params: {'email_check': email},
      );
      return res as bool;
    } catch (e) {
      return false;
    }
  }

  Future<Usuario?> recuperarDadosUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // ATENÇÃO: Confirme se o nome da sua tabela no Supabase é 'usuarios' ou 'profiles'
      final data = await _supabase
          .from('usuarios') // <--- NOME DA TABELA
          .select()
          .eq('id', user.id) // O ID da tabela deve bater com o ID do Auth
          .single();

      // Usa o seu Modelo para converter os dados
      return Usuario.fromMap(data);
    } catch (e) {
      // Se der erro (ex: usuário não existe na tabela ainda), retorna null
      return null;
    }
  }

  // No AuthService.dart

  Future<String?> enviarTokenRecuperacao(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        // Isso envia um código de 6 dígitos (Token) em vez de um Magic Link
        // Nota: Configure o template de e-mail no Supabase para mostrar {{ .Token }}
      );
      return null;
    } catch (e) {
      return "Erro ao enviar código: $e";
    }
  }

  Future<String?> validarTokenEAtualizarSenha(
    String email,
    String token,
    String novaSenha,
  ) async {
    try {
      // 1. Valida o token (código de 6 dígitos)
      final res = await _supabase.auth.verifyOTP(
        token: token,
        type: OtpType.email,
        email: email,
      );

      if (res.session == null) return "Código inválido ou expirado.";

      // 2. Atualiza a senha
      await _supabase.auth.updateUser(UserAttributes(password: novaSenha));

      return null; // Sucesso
    } catch (e) {
      return "Erro ao atualizar senha: $e";
    }
  }
}
