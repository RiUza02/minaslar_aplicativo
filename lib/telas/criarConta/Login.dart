import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../servicos/Autenticacao.dart';
import '../../servicos/Roteador.dart'; // Certifique-se que o caminho está certo
import 'RecuperaSenha.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Instância do serviço
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  // Cores (Mantendo seu padrão)
  final Color _corFundo = Colors.black;
  final Color _corCard = const Color(0xFF1E1E1E);

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Fecha o teclado
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final senha = _senhaController.text.trim();

      // Chama o login do AuthService (que já salva o cache local)
      await _authService.login(email, senha);

      if (!mounted) return;

      // ============================================================
      // A CORREÇÃO PRINCIPAL ESTÁ AQUI:
      // ============================================================
      // Em vez de esperar o StreamBuilder atualizar "por baixo",
      // nós forçamos a navegação para o Roteador, limpando a tela de Login.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Roteador()),
        (route) => false, // Remove todas as rotas anteriores
      );
    } on AuthException catch (e) {
      _mostrarErro(e.message);
      setState(() => _isLoading = false); // Para o loading em caso de erro
    } on SocketException {
      _mostrarErro("Sem conexão com a internet.");
      setState(() => _isLoading = false);
    } catch (e) {
      _mostrarErro("Erro inesperado: $e");
      setState(() => _isLoading = false);
    }
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Layout visual mantido igual
    return Scaffold(
      backgroundColor: _corFundo,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone ou Logo
              Icon(Icons.lock_person, size: 80, color: Colors.blue[900]),
              const SizedBox(height: 30),

              const Text(
                "BEM-VINDO DE VOLTA",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),

              // Formulário
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _corCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // E-mail
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          "E-mail",
                          Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Informe o e-mail';
                          if (!value.contains('@')) return 'E-mail inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Senha
                      TextFormField(
                        controller: _senhaController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          "Senha",
                          Icons.lock_outline,
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Informe a senha'
                            : null,
                      ),
                      const SizedBox(height: 30),

                      // Botão Entrar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _fazerLogin,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "ENTRAR",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Esqueci a senha
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecuperarSenha(),
                            ),
                          );
                        },
                        child: Text(
                          "Esqueci minha senha",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[500]),
      prefixIcon: Icon(icon, color: Colors.blue[900]),
      filled: true,
      fillColor: Colors.black26,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
