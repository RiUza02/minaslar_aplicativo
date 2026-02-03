import 'dart:io'; // Necessário para verificação de internet
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../servicos/Autenticacao.dart';
import '../../servicos/VerificacaoEmail.dart';

class CadastroUsuario extends StatefulWidget {
  const CadastroUsuario({super.key});

  @override
  State<CadastroUsuario> createState() => _CadastroUsuarioState();
}

class _CadastroUsuarioState extends State<CadastroUsuario> {
  // ==================================================
  // CONFIGURAÇÕES VISUAIS
  // ==================================================
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corPrincipal = Colors.blue[900]!;
  final Color corSecundaria = Colors.cyan[400]!;
  final Color corTextoCinza = Colors.grey[500]!;
  final Color corTextoBranco = Colors.white;

  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();

  // Variável de controle de erro específico de banco
  String? _erroEmailJaCadastrado;

  // Máscara
  final maskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // Estados
  bool _isLoading = false;
  bool _senhaValida = false;
  bool _telefoneValido = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmaSenha = false;

  final AuthService _authService = AuthService();

  // ==================================================
  // FUNÇÃO PRINCIPAL DE CADASTRO
  // ==================================================
  Future<void> _cadastrarUsuario() async {
    // Esconde o teclado
    FocusScope.of(context).unfocus();

    try {
      // 1. Resetar estados e iniciar loading
      setState(() {
        _erroEmailJaCadastrado = null;
        _isLoading = true;
      });

      if (!_formKey.currentState!.validate()) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Verificação de Internet
      try {
        final result = await InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 5));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw const SocketException("Sem resposta");
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sem conexão com a internet."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 3. Tenta Cadastrar
      final erroRetornado = await _authService.cadastrarUsuario(
        email: _emailController.text.trim(),
        password: _senhaController.text,
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
        isAdmin: false,
      );

      if (mounted) setState(() => _isLoading = false);

      // ===========================================================
      // 4. TRATAMENTO DO ERRO RETORNADO PELO SERVICE
      // ===========================================================
      if (erroRetornado != null) {
        // Converte tudo para string para facilitar a verificação
        final msg = erroRetornado.toString();

        // Verifica se é o erro de chave estrangeira (23503) ou violação única
        // Isso acontece quando o Auth falha (email duplicado) ou o ID não bate
        if (msg.contains('23503') ||
            msg.contains('foreign key') ||
            msg.contains('already registered') ||
            msg.contains('violates foreign key constraint')) {
          if (mounted) {
            setState(() {
              _erroEmailJaCadastrado = 'E-mail já cadastrado ou inválido.';
            });
            // Força a validação visual do formulário para pintar de vermelho
            _formKey.currentState!.validate();
          }
          return; // Para aqui e não mostra o SnackBar
        }

        // Se for outro erro qualquer, mostra no SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro: $erroRetornado"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 5. Sucesso (erroRetornado é null)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                VerificacaoEmail(email: _emailController.text.trim()),
          ),
        );
      }
    } catch (e) {
      // Caso ocorra um erro grave que não foi pego pelo Service
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro inesperado: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          'Novo Usuário',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
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
                      children: [
                        const SizedBox(height: 10),
                        Icon(
                          Icons.person_add_outlined,
                          size: 50,
                          color: corPrincipal,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "CRIE SUA CONTA",
                          style: TextStyle(
                            color: corTextoCinza,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // DADOS PESSOAIS
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: corCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                "DADOS PESSOAIS",
                                Icons.person,
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _nomeController,
                                label: 'Nome Completo',
                                icon: Icons.person_outline,
                                validator: (v) =>
                                    v!.isEmpty ? 'Informe o nome' : null,
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _emailController,
                                label: 'E-mail',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (_) {
                                  // Limpa o erro ao digitar
                                  if (_erroEmailJaCadastrado != null) {
                                    setState(
                                      () => _erroEmailJaCadastrado = null,
                                    );
                                  }
                                },
                                validator: (v) {
                                  if (!v!.contains('@')) {
                                    return 'E-mail inválido';
                                  }
                                  // Aqui a mágica acontece: retorna o erro do banco
                                  return _erroEmailJaCadastrado;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _telefoneController,
                                label: 'Telefone / Celular',
                                icon: Icons.phone_android,
                                hintText: '(32) 12345-6789',
                                inputFormatters: [maskFormatter],
                                keyboardType: TextInputType.phone,
                                onChanged: (v) {
                                  setState(() {
                                    _telefoneValido = v.length >= 15;
                                  });
                                },
                                validator: (v) {
                                  if (v!.isEmpty) return 'Informe o telefone';
                                  if (v.length < 15) {
                                    return 'Telefone incompleto';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildValidationIndicator(
                                isValid: _telefoneValido,
                                text: 'Mínimo de 11 dígitos',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // SEGURANÇA
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: corCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle("SEGURANÇA", Icons.lock),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _senhaController,
                                label: 'Senha',
                                icon: Icons.lock_outline,
                                obscureText: !_mostrarSenha,
                                onChanged: (v) {
                                  setState(() {
                                    _senhaValida = v.length >= 6;
                                  });
                                },
                                validator: (v) => v!.length < 6
                                    ? 'Mínimo de 6 caracteres'
                                    : null,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _mostrarSenha
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: corTextoCinza,
                                  ),
                                  onPressed: () => setState(
                                    () => _mostrarSenha = !_mostrarSenha,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildValidationIndicator(
                                isValid: _senhaValida,
                                text: 'Mínimo de 6 caracteres',
                              ),

                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _confirmaSenhaController,
                                label: 'Confirmar Senha',
                                icon: Icons.lock_reset,
                                obscureText: !_mostrarConfirmaSenha,
                                onChanged: (value) => setState(() {}),
                                validator: (v) {
                                  if (v!.isEmpty) return 'Confirme sua senha';
                                  if (v != _senhaController.text) {
                                    return 'As senhas não coincidem';
                                  }
                                  return null;
                                },
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _mostrarConfirmaSenha
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: corTextoCinza,
                                  ),
                                  onPressed: () => setState(
                                    () => _mostrarConfirmaSenha =
                                        !_mostrarConfirmaSenha,
                                  ),
                                ),
                              ),

                              if (_confirmaSenhaController.text.isNotEmpty &&
                                  _confirmaSenhaController.text !=
                                      _senhaController.text)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8.0,
                                    left: 4.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red[700],
                                        size: 14,
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
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Botão Criar Conta
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: corPrincipal,
                                  ),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: corPrincipal,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: corPrincipal.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _cadastrarUsuario,
                                  child: const Text(
                                    'CRIAR CONTA',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 40),
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

  // WIDGETS AUXILIARES

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: corTextoCinza, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: corTextoCinza,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    List<MaskTextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffixIcon,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(color: corTextoBranco),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: corTextoCinza.withOpacity(0.5)),
        labelStyle: TextStyle(color: corTextoCinza),
        prefixIcon: Icon(icon, color: corSecundaria),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black26, // Cor fixa para contraste
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: corSecundaria),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildValidationIndicator({
    required bool isValid,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.greenAccent : Colors.redAccent,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.greenAccent : Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
