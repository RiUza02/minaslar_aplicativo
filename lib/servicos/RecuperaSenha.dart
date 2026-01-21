import 'package:flutter/material.dart';
import 'Autenticacao.dart';

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
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 15),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white54),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue),
      ),
      border: const OutlineInputBorder(),
      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recuperar Senha"),
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
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        /// Ícone ilustrativo de recuperação de senha
                        const Icon(
                          Icons.lock_reset,
                          size: 100,
                          color: Colors.blue,
                        ),

                        const SizedBox(height: 30),

                        /// Título da tela
                        const Text(
                          "Esqueceu sua senha?",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// Texto explicativo do processo
                        const Text(
                          "Não se preocupe, insira seu e-mail cadastrado abaixo e um link para redefinir sua senha será enviado.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.white70),
                        ),

                        const SizedBox(height: 40),

                        /// Campo de entrada do e-mail
                        TextFormField(
                          cursorColor: Colors.white,
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
                            if (!v.contains('@')) return 'E-mail inválido';
                            return null;
                          },
                        ),

                        const Spacer(),

                        /// Botão ou indicador de carregamento
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.blue,
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _enviarEmailRecuperacao,
                                  child: const Text(
                                    'ENVIAR LINK DE RECUPERAÇÃO',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                              ),

                        const SizedBox(height: 20),
                      ],
                    ),
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
