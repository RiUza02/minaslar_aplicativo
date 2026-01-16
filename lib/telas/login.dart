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
  // Controladores
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  // Chave do formulário
  final _formKey = GlobalKey<FormState>();

  // Serviço de autenticação
  final AuthService _authService = AuthService();

  // Estado de carregamento
  bool _isLoading = false;

  /// Método de Login
  Future<void> _fazerLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? erro = await _authService.loginUsuario(
        email: _emailController.text,
        password: _senhaController.text,
      );

      setState(() => _isLoading = false);

      if (erro != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(erro, style: const TextStyle(color: Colors.white)),
              backgroundColor: const Color.fromARGB(255, 255, 110, 110),
            ),
          );
        }
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  /// Método auxiliar para estilizar inputs
  /// MUDANÇA AQUI: Ícone agora recebe a cor Colors.blue
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),

      // --- ÍCONE AZUL ---
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
      // O tema global define o fundo, mas garantimos contraste aqui se necessário
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

                        // --- LOGO ---
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

                        // --- CAMPOS ---

                        // E-mail
                        TextFormField(
                          cursorColor: Colors.blue, // Cursor também azul
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(
                            'E-mail',
                            Icons.email,
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Digite seu e-mail' : null,
                        ),

                        const SizedBox(height: 15),

                        // Senha
                        TextFormField(
                          cursorColor: Colors.blue, // Cursor também azul
                          controller: _senhaController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(
                            'Senha',
                            Icons.lock,
                          ),
                          obscureText: true,
                          validator: (v) =>
                              v!.isEmpty ? 'Digite sua senha' : null,
                        ),

                        const SizedBox(height: 20),

                        // --- BOTÃO ---
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
                                      child: const Text(
                                        "Criar Conta",
                                        style: TextStyle(color: Colors.blue),
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
