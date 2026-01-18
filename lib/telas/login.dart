import 'package:flutter/material.dart';
import '../servicos/autenticacao.dart';
import 'Cadastro_login/recuperaSenha.dart';
import 'cadastro.dart';
import 'roteador.dart';

/// Tela responsável pelo login do usuário
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Controladores dos campos de entrada
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  /// Chave do formulário para validação
  final _formKey = GlobalKey<FormState>();

  /// Serviço de autenticação (Supabase)
  final AuthService _authService = AuthService();

  /// Controla exibição do loading
  bool _isLoading = false;

  /// Realiza o login do usuário
  Future<void> _fazerLogin() async {
    // Valida todos os campos do formulário
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Tenta autenticar no Supabase
      String? erro = await _authService.loginUsuario(
        email: _emailController.text,
        password: _senhaController.text,
      );

      // Garante que a tela ainda está montada
      if (!mounted) return;

      setState(() => _isLoading = false);

      // Caso ocorra erro no login
      if (erro != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              erro,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            backgroundColor: const Color.fromARGB(255, 255, 110, 110),
          ),
        );
      } else {
        // ============================================================
        // Login bem-sucedido
        // Navega para o RoteadorTela removendo todas as telas anteriores
        // Isso impede que o usuário volte para o login
        // ============================================================
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RoteadorTela()),
          (route) => false,
        );
      }
    }
  }

  /// Padrão visual dos campos de texto
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 15),
      prefixIcon: Icon(icon, color: Colors.blue),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white54),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue),
      ),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        /// Ícone ilustrativo do login
                        const Icon(
                          Icons.lock_person,
                          size: 120,
                          color: Colors.blue,
                        ),

                        const SizedBox(height: 20),

                        /// Título da tela
                        const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// Campo de e-mail
                        TextFormField(
                          cursorColor: Colors.blue,
                          controller: _emailController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: _buildInputDecoration(
                            'E-mail',
                            Icons.email,
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Digite seu e-mail' : null,
                        ),

                        const SizedBox(height: 15),

                        /// Campo de senha
                        TextFormField(
                          cursorColor: Colors.blue,
                          controller: _senhaController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: _buildInputDecoration(
                            'Senha',
                            Icons.lock,
                          ),
                          obscureText: true,
                          validator: (v) =>
                              v!.isEmpty ? 'Digite sua senha' : null,
                        ),

                        const SizedBox(height: 20),

                        /// Botão de login ou indicador de carregamento
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
                                  onPressed: _fazerLogin,
                                  child: const Text(
                                    'ENTRAR',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),

                        const Spacer(),

                        const Divider(color: Colors.white24),
                        const SizedBox(height: 10),

                        /// Área inferior com ações secundárias
                        IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              /// Criar conta
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      "Não tem conta?",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Navega para a escolha do tipo de cadastro
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const EscolhaTipoCadastroScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Criar Conta",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const VerticalDivider(
                                color: Colors.white24,
                                thickness: 1,
                                width: 20,
                              ),

                              /// Recuperar senha
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      "Esqueceu a senha?",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Navega para a tela de recuperação de senha
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const RecuperarSenhaScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Recuperar",
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
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
