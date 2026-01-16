import 'package:flutter/material.dart';
import '../servicos/autenticacao.dart';
import 'Cadastro_login/recuperaSenha.dart';
import 'cadastro.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para capturar o texto digitado nos campos
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  // Chave global para validar o formulário e gerenciar seu estado
  final _formKey = GlobalKey<FormState>();

  // Serviço de autenticação (comunicação com Firebase/Backend)
  final AuthService _authService = AuthService();

  // Variável de estado para controlar o loading (feedback visual)
  bool _isLoading = false;

  /// Método responsável pela lógica de login
  Future<void> _fazerLogin() async {
    // 1. Valida se os campos estão preenchidos corretamente
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 3. Chama o serviço de autenticação
      String? erro = await _authService.loginUsuario(
        email: _emailController.text,
        password: _senhaController.text,
      );

      setState(() => _isLoading = false);

      // 5. Tratamento de erro
      if (erro != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(erro, style: const TextStyle(color: Colors.white)),
              backgroundColor: const Color.fromARGB(
                255,
                255,
                110,
                110,
              ), // Vermelho customizado
            ),
          );
        }
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  /// Método auxiliar para estilizar inputs
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
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
      // O tema global (main.dart) já define o fundo como preto.
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

                        // --- LOGO / ÍCONE ---
                        const Icon(
                          Icons.lock_person,
                          size: 120,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // --- CAMPOS DE TEXTO ---
                        TextFormField(
                          cursorColor: Colors.white,
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration('E-mail'),
                          validator: (v) =>
                              v!.isEmpty ? 'Digite seu e-mail' : null,
                        ),

                        const SizedBox(height: 15),

                        TextFormField(
                          cursorColor: Colors.white,
                          controller: _senhaController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration('Senha'),
                          obscureText: true,
                          validator: (v) =>
                              v!.isEmpty ? 'Digite sua senha' : null,
                        ),

                        const SizedBox(height: 20),

                        // --- BOTÃO DE AÇÃO ---
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
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
                                  child: const Text('ENTRAR'),
                                ),
                              ),

                        const Spacer(),

                        // --- RODAPÉ ---
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 10),

                        IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Lado Esquerdo: Cadastro
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      "Não tem conta?",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const EscolhaTipoCadastroScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text("Criar Conta"),
                                    ),
                                  ],
                                ),
                              ),

                              const VerticalDivider(
                                color: Colors.white24,
                                thickness: 1,
                                width: 20,
                              ),

                              // Lado Direito: Recuperação
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      "Esqueceu a senha?",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    TextButton(
                                      onPressed: () {
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
