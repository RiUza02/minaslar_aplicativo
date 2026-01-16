import 'package:flutter/material.dart';
import '../../servicos/autenticacao.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  Future<void> _enviarEmailRecuperacao() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Chama o método no AuthService (você precisa adicionar esse método lá, veja abaixo)
      String? erro = await _authService.recuperarSenha(
        email: _emailController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (erro == null) {
        if (mounted) {
          // Sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'E-mail de recuperação enviado! Verifique sua caixa de entrada.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Opcional: Voltar para o login após enviar
          Navigator.pop(context);
        }
      } else {
        // Erro
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(erro),
              backgroundColor: const Color.fromARGB(255, 255, 110, 110),
            ),
          );
        }
      }
    }
  }

  // Mesmo estilo de input da tela de login
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
      // LayoutBuilder para evitar overflow do teclado
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_reset,
                        size: 100,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 30),

                      const Text(
                        "Esqueceu sua senha?",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        "Não se preocupe, insira seu e-mail cadastrado abaixo um link para redefinir sua senha será enviado.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 40),

                      TextFormField(
                        cursorColor: Colors.white,
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('E-mail Cadastrado'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v!.isEmpty) return 'Informe o e-mail';
                          if (!v.contains('@')) return 'E-mail inválido';
                          return null;
                        },
                      ),

                      const SizedBox(height: 30),

                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.blue)
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _enviarEmailRecuperacao,
                                child: const Text('ENVIAR LINK DE RECUPERAÇÃO'),
                              ),
                            ),

                      const SizedBox(height: 20), // Espaço final
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
