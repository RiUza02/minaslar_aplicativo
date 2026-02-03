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

  // Cores do Tema (Consistente com Login/Recuperar)
  final Color _corFundo = Colors.black;
  final Color _corCard = const Color(0xFF1E1E1E);
  final Color _corInput = Colors.black26;

  Future<void> _atualizarSenha() async {
    // Valida o formulário
    if (!_formKey.currentState!.validate()) return;

    // Validação extra de segurança
    if (_senhaController.text != _confirmaSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não conferem!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Redireciona para a tela inicial (Login) e remove o histórico
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper para decoração dos inputs
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
    return Scaffold(
      backgroundColor: _corFundo,
      appBar: AppBar(
        title: const Text(
          'REDEFINIR SENHA',
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
                    children: [
                      const Spacer(),

                      // Card Principal
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              /// Ícone Decorativo
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock_reset,
                                  size: 48,
                                  color: Colors.blue[700],
                                ),
                              ),

                              const SizedBox(height: 20),

                              const Text(
                                "Nova Senha",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                "Crie uma nova senha segura para sua conta.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),

                              const SizedBox(height: 30),

                              /// Campo Nova Senha
                              TextFormField(
                                controller: _senhaController,
                                style: const TextStyle(color: Colors.white),
                                decoration:
                                    _buildInputDecoration(
                                      'Nova Senha',
                                      Icons.lock_outline,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureSenha
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
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

                              const SizedBox(height: 12),

                              /// Indicador visual de validação
                              Row(
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      _senhaValida
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      key: ValueKey(_senhaValida),
                                      color: _senhaValida
                                          ? Colors.greenAccent
                                          : Colors.grey,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mínimo de 6 caracteres',
                                    style: TextStyle(
                                      color: _senhaValida
                                          ? Colors.greenAccent
                                          : Colors.grey,
                                      fontWeight: _senhaValida
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              /// Campo Confirmar Senha
                              TextFormField(
                                controller: _confirmaSenhaController,
                                style: const TextStyle(color: Colors.white),
                                decoration:
                                    _buildInputDecoration(
                                      'Confirmar Nova Senha',
                                      Icons.lock_clock,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirma
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirma =
                                                !_obscureConfirma;
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

                              /// Feedback visual de senhas diferentes (Tempo Real)
                              if (_confirmaSenhaController.text.isNotEmpty &&
                                  _confirmaSenhaController.text !=
                                      _senhaController.text)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8.0, left: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.redAccent,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "As senhas não coincidem",
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 30),

                              /// Botão de Salvar
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[900],
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isLoading
                                      ? null
                                      : _atualizarSenha,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
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
