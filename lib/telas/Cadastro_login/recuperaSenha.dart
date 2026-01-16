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

      String? erro = await _authService.recuperarSenha(
        email: _emailController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (erro == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'E-mail de recuperação enviado! Verifique sua caixa de entrada.',
                // FONTE 20
                style: TextStyle(fontSize: 15),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                erro,
                // FONTE 20
                style: const TextStyle(fontSize: 15),
              ),
              backgroundColor: const Color.fromARGB(255, 255, 110, 110),
            ),
          );
        }
      }
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      // FONTE 20 NO LABEL
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

                        const Icon(
                          Icons.lock_reset,
                          size: 100,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          "Esqueceu sua senha?",
                          style: TextStyle(
                            fontSize: 30, // FONTE 20 (Era 24)
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),

                        const Text(
                          "Não se preocupe, insira seu e-mail cadastrado abaixo um link para redefinir sua senha será enviado.",
                          textAlign: TextAlign.center,
                          // FONTE 20 (Era 16)
                          style: TextStyle(fontSize: 15, color: Colors.white70),
                        ),
                        const SizedBox(height: 40),

                        TextFormField(
                          cursorColor: Colors.white,
                          controller: _emailController,
                          // FONTE 20 NO TEXTO DIGITADO
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
                                    // FONTE 20 NO BOTÃO
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
