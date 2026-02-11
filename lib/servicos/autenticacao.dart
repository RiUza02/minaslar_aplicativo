import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Instância do Supabase
  final SupabaseClient _supabase = Supabase.instance.client;

  // Getter para o usuário atual
  User? get usuarioAtual => _supabase.auth.currentUser;

  // =====================================================
  // LOGIN (COM CACHE DE PERMISSÃO)
  // =====================================================
  Future<void> login(String email, String password) async {
    // 1. Faz o login no Supabase
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw const AuthException('Erro ao realizar login.');
    }

    // 2. Verifica se é Admin olhando os metadados do token
    final metadata = response.user!.appMetadata;
    final bool isAdmin =
        metadata['role'] == 'admin' ||
        metadata['admin'] == true ||
        metadata['is_admin'] == true;

    // 3. Salva essa informação no celular (Cache)
    // Isso permite que o Roteador saiba quem é o usuário rapidamente
    await _salvarDadosLocais(isAdmin);
  }

  // =====================================================
  // GERENCIAMENTO DE CACHE (SharedPreferences)
  // =====================================================

  /// Salva a permissão localmente para acesso rápido
  Future<void> _salvarDadosLocais(bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('IS_ADMIN', isAdmin);
  }

  /// Lê do disco (Método que estava faltando!)
  Future<bool> isUsuarioAdminLocal() async {
    final prefs = await SharedPreferences.getInstance();
    // Se não tiver nada salvo, assume false (Usuário comum) por segurança
    return prefs.getBool('IS_ADMIN') ?? false;
  }

  /// Limpa os dados ao sair
  Future<void> _limparDadosLocais() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('IS_ADMIN');
  }

  // =====================================================
  // CADASTRO
  // =====================================================
  Future<String?> cadastrarUsuario({
    required String email,
    required String password,
    required String nome,
    required String telefone,
    bool isAdmin = false,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nome': nome,
          'telefone': telefone,
          'isAdmin': isAdmin, // A Trigger no banco lerá isso
        },
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Erro inesperado ao criar conta.";
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================
  Future<void> deslogar() async {
    // Limpa o cache antes de sair para o próximo usuário não herdar permissões
    await _limparDadosLocais();
    await _supabase.auth.signOut();
  }

  // =====================================================
  // RECUPERAÇÃO DE SENHA
  // =====================================================
  Future<String?> recuperarSenha({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        // Ajuste a URL se necessário
        redirectTo:
            'https://riuza02.github.io/minaslar_aplicativo/RecuperarEmail.html',
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Erro ao enviar e-mail de recuperação.";
    }
  }

  // =====================================================
  // UTILITÁRIOS
  // =====================================================

  // Verificação instantânea baseada no Token atual (Backup de segurança)
  bool isUsuarioAdmin() {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final metadata = user.appMetadata;
    return metadata['role'] == 'admin' ||
        metadata['admin'] == true ||
        metadata['is_admin'] == true;
  }

  Future<bool> verificarSeEmailExiste(String email) async {
    try {
      final res = await _supabase.rpc(
        'email_existe',
        params: {'email_check': email},
      );
      return res as bool;
    } catch (e) {
      debugPrint('Erro RPC email_existe: $e');
      // Na dúvida, retorna false para não travar o fluxo
      return false;
    }
  }
}
