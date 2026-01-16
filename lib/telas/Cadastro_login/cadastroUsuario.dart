import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
// Certifique-se de que os caminhos dos imports abaixo estão corretos no seu projeto
import '../../servicos/autenticacao.dart';
import 'confirmacaoEmail.dart';

class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  // =========================
  // CONTROLE DO FORMULÁRIO
  // =========================
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();

  // MÁSCARA DE TELEFONE (Brasil)
  final maskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _isLoading = false;

  // CONTROLE DE VISIBILIDADE DAS SENHAS E VALIDAÇÕES VISUAIS
  bool _obscureSenha = true;
  bool _obscureConfirma = true;

  // CORREÇÃO: Variáveis de estado para feedback visual
  bool _senhaValida = false;
  bool _telefoneValido = false; // <--- Esta variável estava faltando

  final AuthService _authService = AuthService();

  // =========================
  // LÓGICA: CADASTRAR USUÁRIO
  // =========================
  Future<void> _cadastrar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 1. Cria a conta de autenticação (Firebase Auth)
      String? erro = await _authService.cadastrarUsuario(
        email: _emailController.text.trim(),
        password: _senhaController.text,
      );

      setState(() => _isLoading = false);

      if (erro == null) {
        if (mounted) {
          // ====================================================
          // 2. SALVAR BACKUP LOCAL
          // ====================================================
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('temp_nome', _nomeController.text.trim());
          await prefs.setString('temp_email', _emailController.text.trim());
          await prefs.setString(
            'temp_telefone',
            _telefoneController.text.trim(),
          );
          await prefs.setBool('temp_isAdmin', false); // Usuário Comum

          // ====================================================
          // 3. NAVEGAÇÃO
          // ====================================================
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificacaoEmailScreen(
                emailUsuario: _emailController.text.trim(),
                nomeUsuario: _nomeController.text.trim(),
                telefoneUsuario: _telefoneController.text.trim(),
                isAdmin: false,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(erro), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color corPrimaria = Colors.blueAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Usuário'),
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
                      children: [
                        const Icon(
                          Icons.person_add,
                          size: 80,
                          color: corPrimaria,
                        ),
                        const SizedBox(height: 20),

                        // Nome
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome Completo',
                            prefixIcon: Icon(Icons.person, color: corPrimaria),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Informe o nome' : null,
                        ),
                        const SizedBox(height: 20),

                        // E-mail
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email, color: corPrimaria),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              !v!.contains('@') ? 'E-mail inválido' : null,
                        ),
                        const SizedBox(height: 20),

                        // ===========================================
                        // CAMPO TELEFONE (COM MÁSCARA)
                        // ===========================================
                        TextFormField(
                          controller: _telefoneController,
                          // Aplica a máscara (##) #####-####
                          inputFormatters: [maskFormatter],
                          decoration: const InputDecoration(
                            labelText: 'Telefone / Celular',
                            prefixIcon: Icon(Icons.phone, color: corPrimaria),
                            hintText: '(32) 12345-6789',
                          ),
                          keyboardType: TextInputType.phone,
                          // CORREÇÃO: Atualizar estado _telefoneValido
                          onChanged: (value) {
                            setState(() {
                              // Verifica se tem 11 dígitos numéricos (padrão celular BR)
                              // maskFormatter.getUnmaskedText() pega apenas os números
                              _telefoneValido =
                                  maskFormatter.getUnmaskedText().length >= 11;
                            });
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe o telefone';
                            }
                            if (maskFormatter.getUnmaskedText().length < 11) {
                              return 'Telefone incompleto';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Feedback Visual do Telefone
                        Row(
                          children: [
                            Icon(
                              _telefoneValido
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: _telefoneValido
                                  ? Colors.green
                                  : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Mínimo de 11 dígitos',
                              style: TextStyle(
                                color: _telefoneValido
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ===========================================
                        // SENHA (COM VISIBILIDADE)
                        // ===========================================
                        TextFormField(
                          controller: _senhaController,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: corPrimaria,
                            ),
                            // Botão do Olho
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
                          validator: (v) => v!.length < 6
                              ? 'A senha não atende aos requisitos mínimos'
                              : null,
                        ),
                        const SizedBox(height: 8),

                        // Feedback Visual da Senha
                        Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 10),
                          child: Row(
                            children: [
                              Icon(
                                _senhaValida
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: _senhaValida ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Mínimo de 6 caracteres',
                                style: TextStyle(
                                  color: _senhaValida
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ===========================================
                        // CONFIRMAR SENHA (COM VISIBILIDADE)
                        // ===========================================
                        TextFormField(
                          controller: _confirmaSenhaController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: 'Confirmar Senha',
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
                          validator: (v) {
                            if (v!.isEmpty) return 'Confirme sua senha';
                            if (v != _senhaController.text) {
                              return 'As senhas não coincidem';
                            }
                            return null;
                          },
                        ),

                        const Spacer(),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: corPrimaria,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                  ),
                                  onPressed: _cadastrar,
                                  child: const Text('CRIAR CONTA'),
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
