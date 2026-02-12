import 'dart:io';
import 'package:flutter/material.dart';
import '../../servicos/Autenticacao.dart';
import 'ValidarCodigo.dart';

class RecuperarSenha extends StatefulWidget {
  const RecuperarSenha({super.key});

  @override
  State<RecuperarSenha> createState() => _RecuperarSenhaState();
}

class _RecuperarSenhaState extends State<RecuperarSenha> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final Color _corFundo = Colors.black;
  final Color _corCard = const Color(0xFF1E1E1E);
  final Color _corInput = Colors.black26;

  // ============================================================
  // LÓGICA DE ENVIO COM VALIDAÇÕES
  // ============================================================
  Future<void> _enviarEmailRecuperacao() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
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

      // CORREÇÃO AQUI: Removemos o "email: " pois o parâmetro é posicional
      String? erro = await _authService.enviarTokenRecuperacao(email);

      if (erro != null) throw erro;

      if (!mounted) return;

      _showSnackBar('Código enviado! Verifique seu e-mail.', isError: false);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ValidarCodigo(email: email)),
      );
    } on SocketException {
      _showSnackBar("Sem conexão com a internet.", isError: true);
    } catch (e) {
      String msg = e.toString().replaceAll("Exception: ", "");
      _showSnackBar(msg, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                                  Icons.lock_reset_rounded,
                                  size: 48,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Esqueceu a senha?",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // ATUALIZADO: Texto mudado de "link" para "código"
                              Text(
                                "Não se preocupe. Digite seu e-mail abaixo e enviaremos um código de verificação.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                  height: 1.5,
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
                                  'E-mail Cadastrado',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v!.isEmpty) return 'Informe o e-mail';
                                  if (!v.contains('@'))
                                    return 'E-mail inválido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
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
                                        // ATUALIZADO: Texto do botão
                                        child: const Text(
                                          'ENVIAR CÓDIGO',
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
