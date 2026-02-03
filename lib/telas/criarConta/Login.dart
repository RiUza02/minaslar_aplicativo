import 'dart:io'; // Necessário para SocketException (Sem internet)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Necessário para AuthException
import '../../servicos/Autenticacao.dart';
import 'RecuperaSenha.dart';
import 'Cadastro.dart';
import '../../servicos/roteador.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  // Cores do tema
  final Color _corFundo = Colors.black;
  final Color _corCard = const Color(0xFF1E1E1E);
  final Color _corInput = Colors.black26;

  /// Realiza o login do usuário com verificação prévia de internet
  Future<void> _fazerLogin() async {
    // 1. Validações locais (campo vazio, etc)
    if (!_formKey.currentState!.validate()) return;

    // Esconde o teclado para limpar a visão
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    // ===========================================================
    // 2. VERIFICAÇÃO DE INTERNET (Igual ao Cadastro)
    // ===========================================================
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));

      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException("Sem resposta");
      }
    } catch (_) {
      // Se cair aqui, é CERTEZA que é falta de internet
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Sem conexão com a internet.", isError: true);
      }
      return; // Para tudo aqui
    }

    // ===========================================================
    // 3. TENTATIVA DE LOGIN (Agora sabemos que tem internet)
    // ===========================================================
    try {
      // Se der erro aqui, é 99% de chance de ser senha/email errados
      await _authService.loginUsuario(
        email: _emailController.text,
        password: _senhaController.text,
      );

      if (!mounted) return;

      // Sucesso!
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Roteador()),
        (route) => false,
      );
    } on AuthException catch (e) {
      // TRATAMENTO: Credenciais Incorretas
      // Como já passamos pelo teste de internet, esse erro é do Auth mesmo
      String mensagem = "E-mail ou senha incorretos.";

      // Casos específicos extras (opcional)
      if (e.message.toLowerCase().contains("confirm")) {
        mensagem = "Confirme seu cadastro no e-mail recebido.";
      }

      _showSnackBar(mensagem, isError: true);
    } catch (e) {
      // Erro inesperado (bug no app, servidor caiu, etc)
      _showSnackBar(
        "Ocorreu um erro inesperado. Tente novamente.",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Helper para exibir mensagens (Evita repetição de código)
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
            ? const Color.fromARGB(255, 200, 60, 60) // Vermelho mais suave
            : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
      prefixIcon: Icon(icon, color: Colors.blue[700]),
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
    // O restante do seu build permanece igual, pois a lógica está isolada no _fazerLogin
    return Scaffold(
      backgroundColor: _corFundo,
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
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock_person_rounded,
                                  size: 48,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Bem-vindo",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Faça login para continuar",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 32),
                              TextFormField(
                                cursorColor: Colors.blue,
                                controller: _emailController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                decoration: _buildInputDecoration(
                                  'E-mail',
                                  Icons.email_outlined,
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? 'Digite seu e-mail' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                cursorColor: Colors.blue,
                                controller: _senhaController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                decoration: _buildInputDecoration(
                                  'Senha',
                                  Icons.lock_outline,
                                ),
                                obscureText: true,
                                validator: (v) =>
                                    v!.isEmpty ? 'Digite sua senha' : null,
                              ),
                              const SizedBox(height: 30),
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
                                        onPressed: _fazerLogin,
                                        child: const Text(
                                          'ENTRAR',
                                          style: TextStyle(
                                            fontSize: 18,
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
                      const Spacer(),
                      Divider(color: Colors.white.withValues(alpha: 0.1)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Cadastro(),
                                ),
                              );
                            },
                            child: const Text(
                              "Criar nova conta",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            height: 20,
                            width: 1,
                            color: Colors.white24,
                          ),
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
                              "Esqueci a senha",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
