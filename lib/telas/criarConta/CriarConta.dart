import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../servicos/autenticacao.dart';
import '../../servicos/VerificacaoEmail.dart';

class CriarConta extends StatefulWidget {
  final bool isAdmin;
  final Color corPrincipal;
  final Color corSecundaria;

  const CriarConta({
    super.key,
    required this.isAdmin,
    required this.corPrincipal,
    required this.corSecundaria,
  });

  @override
  State<CriarConta> createState() => _CriarContaState();
}

class _CriarContaState extends State<CriarConta> {
  // ==================================================
  // CONSTANTES VISUAIS
  // ==================================================
  final Color _corFundo = Colors.black;
  final Color _corCard = const Color(0xFF1E1E1E);
  final Color _corTextoCinza = Colors.grey[500]!;
  final Color _corTextoBranco = Colors.white;

  final _formKey = GlobalKey<FormState>();

  // ==================================================
  // CONTROLADORES
  // ==================================================
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _senhaController;
  late final TextEditingController _confirmaSenhaController;
  late final TextEditingController _codigoSegurancaController;

  // Máscara
  final _maskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // Estados
  String? _erroEmailJaCadastrado;
  bool _isLoading = false;
  bool _senhaValida = false;
  bool _telefoneValido = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmaSenha = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _emailController = TextEditingController();
    _telefoneController = TextEditingController();
    _senhaController = TextEditingController();
    _confirmaSenhaController = TextEditingController();
    _codigoSegurancaController = TextEditingController();
  }

  // ==================================================
  // DISPOSE (GERENCIAMENTO DE MEMÓRIA)
  // ==================================================
  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmaSenhaController.dispose();
    _codigoSegurancaController.dispose();
    super.dispose();
  }

  // ==================================================
  // LÓGICA DE CADASTRO
  // ==================================================
  Future<void> _realizarCadastro() async {
    FocusScope.of(context).unfocus();

    try {
      setState(() {
        _erroEmailJaCadastrado = null;
        _isLoading = true;
      });

      // Validação do Form
      if (!_formKey.currentState!.validate()) {
        setState(() => _isLoading = false);
        return;
      }

      // Verificação de Internet
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

      // Chamada ao Service
      final erroRetornado = await _authService.cadastrarUsuario(
        email: _emailController.text.trim(),
        password: _senhaController.text,
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
        isAdmin: widget.isAdmin,
      );

      if (mounted) setState(() => _isLoading = false);

      if (erroRetornado != null) {
        final msg = erroRetornado.toString();
        if (msg.contains('23503') ||
            msg.contains('foreign key') ||
            msg.contains('already registered') ||
            msg.contains('violates foreign key constraint')) {
          if (mounted) {
            setState(() {
              _erroEmailJaCadastrado = 'E-mail já cadastrado ou inválido.';
            });
            _formKey.currentState!.validate();
          }
          return;
        }

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

      // Sucesso
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                VerificacaoEmail(email: _emailController.text.trim()),
          ),
        );
      }
    } catch (e) {
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
    // Define textos baseados no tipo de usuário
    final String tituloAppbar = widget.isAdmin
        ? 'Novo Administrador'
        : 'Novo Usuário';
    final String textoHeader = widget.isAdmin
        ? "DADOS DO ADMINISTRADOR"
        : "CRIE SUA CONTA";
    final IconData iconeHeader = widget.isAdmin
        ? Icons.admin_panel_settings
        : Icons.person_add_outlined;

    return Scaffold(
      backgroundColor: _corFundo,
      appBar: AppBar(
        title: Text(
          tituloAppbar,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: widget.corPrincipal,
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
                        Icon(iconeHeader, size: 50, color: widget.corPrincipal),
                        const SizedBox(height: 8),
                        Text(
                          textoHeader,
                          style: TextStyle(
                            color: _corTextoCinza,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ======================
                        // DADOS PESSOAIS
                        // ======================
                        _buildCardContainer(
                          titulo: "DADOS PESSOAIS",
                          icone: Icons.person,
                          children: [
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
                                if (_erroEmailJaCadastrado != null) {
                                  setState(() => _erroEmailJaCadastrado = null);
                                }
                              },
                              validator: (v) {
                                if (!v!.contains('@')) return 'E-mail inválido';
                                return _erroEmailJaCadastrado;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _telefoneController,
                              label: 'Telefone / Celular',
                              icon: Icons.phone_android,
                              hintText: '(32) 12345-6789',
                              inputFormatters: [_maskFormatter],
                              keyboardType: TextInputType.phone,
                              onChanged: (v) => setState(
                                () => _telefoneValido = v.length >= 15,
                              ),
                              validator: (v) {
                                if (v!.isEmpty) return 'Informe o telefone';
                                if (v.length < 15) return 'Telefone incompleto';
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

                        const SizedBox(height: 20),

                        // ======================
                        // SEGURANÇA
                        // ======================
                        _buildCardContainer(
                          titulo: "SEGURANÇA",
                          icone: Icons.lock,
                          children: [
                            _buildTextField(
                              controller: _senhaController,
                              label: 'Senha',
                              icon: Icons.lock_outline,
                              obscureText: !_mostrarSenha,
                              onChanged: (v) =>
                                  setState(() => _senhaValida = v.length >= 6),
                              validator: (v) => v!.length < 6
                                  ? 'Mínimo de 6 caracteres'
                                  : null,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _mostrarSenha
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: _corTextoCinza,
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
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                if (v!.isEmpty) return 'Confirme sua senha';
                                if (v != _senhaController.text)
                                  return 'As senhas não coincidem';
                                return null;
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _mostrarConfirmaSenha
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: _corTextoCinza,
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

                        // ======================
                        // ÁREA RESTRITA (SÓ ADMIN)
                        // ======================
                        if (widget.isAdmin) ...[
                          const SizedBox(height: 20),
                          _buildCardContainer(
                            titulo: "ÁREA RESTRITA",
                            icone: Icons.vpn_key,
                            children: [
                              _buildTextField(
                                controller: _codigoSegurancaController,
                                label: 'Código da Empresa',
                                icon: Icons.security,
                                obscureText: true,
                                validator: (v) =>
                                    v != '123456' ? 'Código incorreto' : null,
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 40),

                        // ======================
                        // BOTÃO DE AÇÃO
                        // ======================
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: widget.corPrincipal,
                                  ),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.corPrincipal,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: widget.corPrincipal.withValues(
                                      alpha: 0.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _realizarCadastro,
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
  // HELPER WIDGETS
  // ==================================================

  // Container estilizado (Card) para evitar repetição no build
  Widget _buildCardContainer({
    required String titulo,
    required IconData icone,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _corCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: _corTextoCinza, size: 16),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  color: _corTextoCinza,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
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
      style: TextStyle(color: _corTextoBranco),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: _corTextoCinza.withValues(alpha: 0.5)),
        labelStyle: TextStyle(color: _corTextoCinza),
        prefixIcon: Icon(
          icon,
          color: widget.corSecundaria,
        ), // Usa a cor secundária passada
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black26,
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
          borderSide: BorderSide(color: widget.corSecundaria),
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
