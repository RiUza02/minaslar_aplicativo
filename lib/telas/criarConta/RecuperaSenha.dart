import 'dart:io'; // Importante para checar conexão (SocketException)
import 'package:flutter/material.dart';
import '../../servicos/Autenticacao.dart';

/// Tela responsável pela recuperação de senha via e-mail
class RecuperarSenha extends StatefulWidget {
  const RecuperarSenha({super.key});

  @override
  State<RecuperarSenha> createState() => _RecuperarSenhaState();
}

class _RecuperarSenhaState extends State<RecuperarSenha> {
  /// Controller do campo de e-mail
  final _emailController = TextEditingController();

  /// Chave do formulário para validação
  final _formKey = GlobalKey<FormState>();

  /// Serviço de autenticação (Supabase)
  final AuthService _authService = AuthService();

  /// Controla o estado de carregamento da tela
  bool _isLoading = false;

  /// Cores do tema
  final Color _corFundo = Colors.black;
  final Color _corCard = const Color(0xFF1E1E1E);
  final Color _corInput = Colors.black26;

  // ============================================================
  // LÓGICA DE ENVIO COM VALIDAÇÕES
  // ============================================================
  Future<void> _enviarEmailRecuperacao() async {
    // 1. Validação do formulário
    if (!_formKey.currentState!.validate()) return;

    // Fecha o teclado para melhor UX
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      // 2. VERIFICAÇÃO DE CONEXÃO COM A INTERNET
      // Tentamos buscar o endereço do Google. Se falhar, não tem internet.
      try {
        final result = await InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 5));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw const SocketException("Sem resposta");
        }
      } catch (_) {
        throw const SocketException("Sem internet");
      }

      final email = _emailController.text.trim();

      // 3. VERIFICAÇÃO SE O E-MAIL EXISTE NO BANCO
      // Usamos aquela função RPC do seu AuthService
      final bool existe = await _authService.verificarSeEmailExiste(email);

      if (!existe) {
        // Se cair aqui, interrompemos o processo
        throw "Este e-mail não está cadastrado no sistema.";
      }

      // 4. ENVIA O E-MAIL DE RECUPERAÇÃO
      // Agora sabemos que tem internet e o usuário existe
      String? erro = await _authService.recuperarSenha(email: email);

      if (erro != null) {
        throw erro; // Repassa o erro do Supabase se houver
      }

      if (!mounted) return;

      // 5. SUCESSO
      _showSnackBar(
        'E-mail enviado! Verifique sua caixa de entrada.',
        isError: false,
      );

      // Aguarda um pouco para o usuário ler e volta para o login
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } on SocketException {
      // TRATAMENTO: Sem Internet
      _showSnackBar("Sem conexão com a internet.", isError: true);
    } catch (e) {
      // TRATAMENTO: E-mail não cadastrado ou Erro Genérico
      // Removemos o "Exception:" da mensagem se houver
      String msg = e.toString().replaceAll("Exception: ", "");
      _showSnackBar(msg, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // HELPER PARA EXIBIR MENSAGENS (SnackBar Bonito)
  // ============================================================
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color.fromARGB(255, 200, 60, 60)
            : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ============================================================
  // PADRONIZA A DECORAÇÃO DOS CAMPOS DE TEXTO
  // ============================================================
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
      prefixIcon: Icon(Icons.email_outlined, color: Colors.blue[700]),
      filled: true,
      fillColor: _corInput,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _corFundo,
      appBar: AppBar(
        title: const Text(
          "RECUPERAÇÃO",
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Container Principal (Card)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _corCard,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              /// Ícone ilustrativo
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock_reset_rounded,
                                  size: 48,
                                  color: Colors.blue[700],
                                ),
                              ),

                              const SizedBox(height: 20),

                              /// Título da tela
                              const Text(
                                "Esqueceu a senha?",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 10),

                              /// Texto explicativo
                              Text(
                                "Não se preocupe. Digite seu e-mail abaixo e enviaremos um link para redefinir sua senha.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 32),

                              /// Campo de entrada do e-mail
                              TextFormField(
                                cursorColor: Colors.blue,
                                controller: _emailController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                decoration: _buildInputDecoration(
                                  'E-mail Cadastrado',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v!.isEmpty) return 'Informe o e-mail';
                                  if (!v.contains('@')) {
                                    return 'E-mail inválido';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              /// Botão ou indicador de carregamento
                              _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.blue,
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[900],
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: _enviarEmailRecuperacao,
                                        child: const Text(
                                          'ENVIAR LINK',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
