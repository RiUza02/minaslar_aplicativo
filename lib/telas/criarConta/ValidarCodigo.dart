import 'package:flutter/material.dart';
import '../../servicos/Autenticacao.dart';

class ValidarCodigo extends StatefulWidget {
  final String email;

  // Recebemos o e-mail da tela anterior para saber quem está trocando a senha
  const ValidarCodigo({super.key, required this.email});

  @override
  State<ValidarCodigo> createState() => _ValidarCodigoState();
}

class _ValidarCodigoState extends State<ValidarCodigo> {
  final _codigoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscureSenha = true;

  // Cores do tema (mesmo padrão da tela anterior)
  final Color _corFundo = Colors.black;
  final Color _corCard = const Color(0xFF1E1E1E);
  final Color _corInput = Colors.black26;

  Future<void> _validarEAlterar() async {
    if (!_formKey.currentState!.validate()) return;

    // Fecha teclado
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final codigo = _codigoController.text.trim();
      final novaSenha = _senhaController.text.trim();

      // Chama o serviço que valida o token e atualiza a senha
      String? erro = await _authService.validarTokenEAtualizarSenha(
        widget.email,
        codigo,
        novaSenha,
      );

      if (erro != null) throw erro;

      if (!mounted) return;

      // SUCESSO!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Senha alterada com sucesso! Faça login."),
          backgroundColor: Colors.green[700],
        ),
      );

      // Volta para a tela de Login (remove tudo da pilha)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      String msg = e.toString().replaceAll("Exception: ", "");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro: $msg"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
      prefixIcon: Icon(icon, color: Colors.blue[700]),
      filled: true,
      fillColor: _corInput,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
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
          "VALIDAR CÓDIGO",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _corCard,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 50,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Código enviado para:\n${widget.email}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 30),

                    // CAMPO CÓDIGO
                    TextFormField(
                      controller: _codigoController,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 5,
                      ),
                      textAlign: TextAlign.center,
                      decoration:
                          _buildInputDecoration(
                            'Código (6 dígitos)',
                            Icons.numbers,
                          ).copyWith(
                            counterText: "", // Esconde o contador de caracteres
                          ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'Digite o código completo';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // CAMPO NOVA SENHA
                    TextFormField(
                      controller: _senhaController,
                      obscureText: _obscureSenha,
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          _buildInputDecoration(
                            'Nova Senha',
                            Icons.lock,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureSenha
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                () => _obscureSenha = !_obscureSenha,
                              ),
                            ),
                          ),
                      validator: (v) {
                        if (v!.isEmpty) return 'Digite a nova senha';
                        if (v.length < 6) return 'Mínimo de 6 caracteres';
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    // BOTÃO
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.blue)
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[900],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _validarEAlterar,
                              child: const Text(
                                "SALVAR NOVA SENHA",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
