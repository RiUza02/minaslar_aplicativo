import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../servicos/autenticacao.dart';
import '../../servicos/VerificacaoEmail.dart';

/// Tela responsável pelo cadastro de usuários administradores
class CadastroAdmin extends StatefulWidget {
  const CadastroAdmin({super.key});

  @override
  State<CadastroAdmin> createState() => _CadastroAdminState();
}

class _CadastroAdminState extends State<CadastroAdmin> {
  // ==================================================
  // CONFIGURAÇÕES VISUAIS (PADRÃO DARK)
  // ==================================================
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;
  final Color corTextoCinza = Colors.grey[500]!;
  final Color corTextoBranco = Colors.white;

  /// Chave do formulário para validações
  final _formKey = GlobalKey<FormState>();

  /// Controladores dos campos do formulário
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();
  final _codigoSegurancaController = TextEditingController();

  /// Mensagem de erro caso o e-mail já esteja cadastrado
  String? _erroEmailJaCadastrado;

  /// Máscara para o campo de telefone
  final maskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  /// Estados de controle da interface
  bool _isLoading = false;
  bool _senhaValida = false;
  bool _telefoneValido = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmaSenha = false;

  /// Serviço de autenticação
  final AuthService _authService = AuthService();

  /// Realiza o cadastro de um administrador
  Future<void> _cadastrarAdmin() async {
    // Limpa erros anteriores e ativa o loading
    setState(() {
      _erroEmailJaCadastrado = null;
      _isLoading = true;
    });

    // Validação dos campos do formulário
    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    // Verifica se o e-mail já existe no banco
    if (_emailController.text.contains('@')) {
      final existe = await _authService.verificarSeEmailExiste(
        _emailController.text.trim(),
      );

      if (existe && mounted) {
        setState(() {
          _erroEmailJaCadastrado = 'Este e-mail já está em uso.';
          _isLoading = false;
        });

        // Força revalidação do formulário
        _formKey.currentState!.validate();
        return;
      }
    }

    // Tenta realizar o cadastro
    final erro = await _authService.cadastrarUsuario(
      email: _emailController.text.trim(),
      password: _senhaController.text,
      nome: _nomeController.text.trim(),
      telefone: _telefoneController.text.trim(),
      isAdmin: true, // Sempre true nesta tela
    );

    if (mounted) setState(() => _isLoading = false);

    if (erro == null && mounted) {
      // Cadastro realizado com sucesso
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              VerificacaoEmail(email: _emailController.text.trim()),
        ),
      );
    } else if (mounted) {
      // Exibe erro retornado pelo Supabase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $erro"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          'Novo Administrador',
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
                        // Cabeçalho da Tela
                        const SizedBox(height: 10),
                        Icon(
                          Icons.admin_panel_settings,
                          size: 50,
                          color: corPrincipal,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "PREENCHA OS DADOS",
                          style: TextStyle(
                            color: corTextoCinza,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // =====================================================
                        // BLOCO 1: DADOS PESSOAIS (Nome, Email, Telefone)
                        // =====================================================
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: corCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
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

                              // Nome
                              _buildTextField(
                                controller: _nomeController,
                                label: 'Nome Completo',
                                icon: Icons.person_outline,
                                backgroundColor: Colors.black26,
                                validator: (v) =>
                                    v!.isEmpty ? 'Informe o nome' : null,
                              ),
                              const SizedBox(height: 16),

                              // Email
                              _buildTextField(
                                controller: _emailController,
                                label: 'E-mail',
                                icon: Icons.email_outlined,
                                backgroundColor: Colors.black26,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (_) {
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
                                  return _erroEmailJaCadastrado;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Telefone
                              _buildTextField(
                                controller: _telefoneController,
                                label: 'Telefone / Celular',
                                icon: Icons.phone_android,
                                backgroundColor: Colors.black26,
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

                              // Validação Visual Telefone
                              const SizedBox(height: 8),
                              _buildValidationIndicator(
                                isValid: _telefoneValido,
                                text: 'Mínimo de 11 dígitos',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // =====================================================
                        // BLOCO 2: SEGURANÇA (Senhas)
                        // =====================================================
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: corCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle("SEGURANÇA", Icons.lock),
                              const SizedBox(height: 16),

                              // Senha
                              _buildTextField(
                                controller: _senhaController,
                                label: 'Senha',
                                icon: Icons.lock_outline,
                                backgroundColor: Colors.black26,
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

                              // Confirmar Senha
                              _buildTextField(
                                controller: _confirmaSenhaController,
                                label: 'Confirmar Senha',
                                icon: Icons.lock_reset,
                                backgroundColor: Colors.black26,
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

                              // Erro visual de senha não coincidente
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

                        const SizedBox(height: 20),

                        // =====================================================
                        // BLOCO 3: ÁREA RESTRITA (Código Empresa)
                        // =====================================================
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: corCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                "ÁREA RESTRITA",
                                Icons.vpn_key,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _codigoSegurancaController,
                                label: 'Código da Empresa',
                                icon: Icons.security,
                                backgroundColor: Colors.black26,
                                obscureText: true,
                                validator: (v) =>
                                    v != '123456' ? 'Código incorreto' : null,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Botão de Criar Conta
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
                                    shadowColor: corPrincipal.withValues(
                                      alpha: 0.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _cadastrarAdmin,
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

  // ==================================================
  // WIDGETS AUXILIARES
  // ==================================================

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
    Color? backgroundColor,
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
        hintStyle: TextStyle(color: corTextoCinza.withValues(alpha: 0.5)),
        labelStyle: TextStyle(color: corTextoCinza),
        prefixIcon: Icon(icon, color: corSecundaria),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: backgroundColor ?? corCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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
