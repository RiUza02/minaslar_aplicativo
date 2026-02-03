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
  // ENVIA O E-MAIL DE RECUPERAÇÃO DE SENHA
  // ============================================================
  Future<void> _enviarEmailRecuperacao() async {
    // Valida o formulário antes de prosseguir
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Solicita ao Supabase o envio do e-mail de recuperação
      String? erro = await _authService.recuperarSenha(
        email: _emailController.text.trim(),
      );

      setState(() => _isLoading = false);

      // Caso não haja erro, exibe mensagem de sucesso
      if (erro == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'E-mail de recuperação enviado! Verifique sua caixa de entrada.',
                style: TextStyle(fontSize: 15),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Retorna para a tela anterior (login)
          Navigator.pop(context);
        }
      } else {
        // Caso haja erro, exibe mensagem de falha
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(erro, style: const TextStyle(fontSize: 15)),
              backgroundColor: const Color.fromARGB(255, 255, 110, 110),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
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
