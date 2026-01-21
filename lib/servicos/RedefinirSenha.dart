import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RedefinirSenhaScreen extends StatefulWidget {
  const RedefinirSenhaScreen({super.key});

  @override
  State<RedefinirSenhaScreen> createState() => _RedefinirSenhaScreenState();
}

class _RedefinirSenhaScreenState extends State<RedefinirSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();

  bool _isLoading = false;
  bool _obscureSenha = true;
  bool _obscureConfirma = true;
  bool _senhaValida = false;

  Future<void> _atualizarSenha() async {
    // Valida o formulário
    if (!_formKey.currentState!.validate()) return;

    // Validação extra de segurança
    if (_senhaController.text != _confirmaSenhaController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('As senhas não conferem!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Atualiza a senha no Supabase
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _senhaController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Redireciona para a tela inicial (Login) e remove o histórico
        // Ajuste a rota '/' conforme seu main.dart (geralmente é o Wrapper ou Login)
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mesma cor usada no CadastroUsuario
    const Color corPrimaria = Colors.blueAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redefinir Senha'),
        centerTitle: true,
        backgroundColor: corPrimaria,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_reset,
                          size: 80,
                          color: corPrimaria,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Crie uma nova senha segura para sua conta.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 30),

                        /// Campo Nova Senha
                        TextFormField(
                          controller: _senhaController,
                          decoration: InputDecoration(
                            labelText: 'Nova Senha',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: corPrimaria,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureSenha
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureSenha = !_obscureSenha;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureSenha,
                          onChanged: (valor) {
                            setState(() {
                              _senhaValida = valor.length >= 6;
                            });
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe a nova senha';
                            }
                            if (v.length < 6) {
                              return 'A senha deve ter no mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        /// Indicador visual de validação (igual ao Cadastro)
                        Row(
                          children: [
                            Icon(
                              _senhaValida ? Icons.check_circle : Icons.cancel,
                              color: _senhaValida ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Mínimo de 6 caracteres',
                              style: TextStyle(
                                color: _senhaValida ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// Campo Confirmar Senha
                        TextFormField(
                          controller: _confirmaSenhaController,
                          decoration: InputDecoration(
                            labelText: 'Confirmar Nova Senha',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: corPrimaria,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirma
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirma = !_obscureConfirma;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureConfirma,
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Confirme a senha';
                            }
                            if (v != _senhaController.text) {
                              return 'As senhas não coincidem';
                            }
                            return null;
                          },
                        ),

                        /// Feedback visual de senhas diferentes
                        if (_confirmaSenhaController.text.isNotEmpty &&
                            _confirmaSenhaController.text !=
                                _senhaController.text)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 6.0,
                              left: 12.0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[700],
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "As senhas não coincidem",
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const Spacer(),

                        /// Botão de Salvar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: corPrimaria,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            onPressed: _isLoading ? null : _atualizarSenha,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'SALVAR NOVA SENHA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
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
