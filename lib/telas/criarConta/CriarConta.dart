import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../servicos/Autenticacao.dart';
import '../../servicos/servicos.dart';

class CriarConta extends StatefulWidget {
  const CriarConta({super.key});

  @override
  State<CriarConta> createState() => _CriarContaState();
}

class _CriarContaState extends State<CriarConta> {
  // ==================================================
  // CONFIGURAÇÕES DE CORES
  // ==================================================
  late Color _corPrincipal;
  late Color _corSecundaria;
  final Color _corFundo = Colors.black;
  final Color _corCard = const Color(0xFF1E1E1E);
  final Color _corTextoCinza = Colors.grey[500]!;
  final Color _corTextoBranco = Colors.white;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _senhaController;
  late final TextEditingController _confirmaSenhaController;

  final _maskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

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

    _corPrincipal = Colors.blue[900]!;
    _corSecundaria = Colors.cyan[400]!;

    _nomeController = TextEditingController();
    _emailController = TextEditingController();
    _telefoneController = TextEditingController();
    _senhaController = TextEditingController();
    _confirmaSenhaController = TextEditingController();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmaSenhaController.dispose();
    super.dispose();
  }

  Future<void> _realizarCadastro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    bool internetAtiva = await Servicos.temConexao();
    if (!internetAtiva) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Sem conexão com a internet. Verifique sua rede e tente novamente.",
            ),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return; // Interrompe a função aqui, não tenta cadastrar
    }

    final erro = await _authService.cadastrarUsuario(
      email: _emailController.text.trim(),
      password: _senhaController.text,
      nome: _nomeController.text.trim(),
      telefone: _telefoneController.text,
      isAdmin: false, // Sempre falso para cadastro público
    );

    setState(() => _isLoading = false);

    if (erro == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                VerificacaoEmail(email: _emailController.text.trim()),
          ),
        );
      }
    } else {
      if (erro == 'EMAIL_JA_CADASTRADO') {
        setState(() {
          _erroEmailJaCadastrado = 'E-mail já está em uso';
        });
        _formKey.currentState!.validate();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro: $erro"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const String tituloAppbar = 'Novo Usuário';
    const String textoHeader = "CRIE SUA CONTA";
    const IconData iconeHeader = Icons.person_add_outlined;

    return Scaffold(
      backgroundColor: _corFundo,
      appBar: AppBar(
        title: Text(
          tituloAppbar,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: _corPrincipal,
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
                        Icon(iconeHeader, size: 50, color: _corPrincipal),
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

                        // DADOS PESSOAIS
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
                              hintText: '(32) 99999-9999',
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

                        // SEGURANÇA
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
                                  color: _corTextoCinza,
                                ),
                                onPressed: () => setState(
                                  () => _mostrarConfirmaSenha =
                                      !_mostrarConfirmaSenha,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // BOTÃO DE AÇÃO
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: _corPrincipal,
                                  ),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _corPrincipal,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: _corPrincipal.withValues(
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

                        const SizedBox(height: 24),

                        // --- NOVO: LINK PARA VOLTAR AO LOGIN ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Já tem uma conta?",
                              style: TextStyle(color: _corTextoCinza),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigator.pop remove a tela atual e volta para a anterior (Login)
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Faça Login",
                                style: TextStyle(
                                  color: _corPrincipal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
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
        prefixIcon: Icon(icon, color: _corSecundaria),
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
          borderSide: BorderSide(color: _corSecundaria),
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
