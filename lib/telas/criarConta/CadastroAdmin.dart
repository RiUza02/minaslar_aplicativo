import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../servicos/autenticacao.dart';
import 'VerificacaoEmail.dart';

/// Tela responsável pelo cadastro de usuários administradores
class CadastroAdminScreen extends StatefulWidget {
  const CadastroAdminScreen({super.key});

  @override
  State<CadastroAdminScreen> createState() => _CadastroAdminScreenState();
}

class _CadastroAdminScreenState extends State<CadastroAdminScreen> {
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
    const Color corAdmin = Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Administrador'),
        centerTitle: true,
        backgroundColor: corAdmin,
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
                          Icons.admin_panel_settings,
                          size: 80,
                          color: corAdmin,
                        ),

                        const SizedBox(height: 20),

                        /// Nome
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome Completo',
                            prefixIcon: Icon(Icons.person, color: corAdmin),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Informe o nome' : null,
                        ),

                        const SizedBox(height: 20),

                        /// E-mail
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email, color: corAdmin),
                          ),
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

                        const SizedBox(height: 20),

                        /// Telefone
                        TextFormField(
                          controller: _telefoneController,
                          inputFormatters: [maskFormatter],
                          decoration: const InputDecoration(
                            labelText: 'Telefone / Celular',
                            prefixIcon: Icon(Icons.phone, color: corAdmin),
                            hintText: '(32) 12345-6789',
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (v) {
                            setState(() {
                              _telefoneValido = v.length >= 15;
                            });
                          },
                          validator: (v) {
                            if (v!.isEmpty) return 'Informe o telefone';
                            if (v.length < 15) return 'Telefone incompleto';
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        /// Indicador visual de telefone válido
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
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// Senha
                        TextFormField(
                          controller: _senhaController,
                          obscureText: !_mostrarSenha,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock, color: corAdmin),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _mostrarSenha
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _mostrarSenha = !_mostrarSenha;
                                });
                              },
                            ),
                          ),
                          onChanged: (v) {
                            setState(() {
                              _senhaValida = v.length >= 6;
                            });
                          },
                          validator: (v) => v!.length < 6
                              ? 'A senha deve ter no mínimo 6 caracteres'
                              : null,
                        ),

                        const SizedBox(height: 8),

                        /// Indicador visual de senha válida
                        Row(
                          children: [
                            Icon(
                              _senhaValida ? Icons.check_circle : Icons.cancel,
                              color: _senhaValida ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Mínimo de 6 caracteres',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// Confirmação de senha
                        TextFormField(
                          controller: _confirmaSenhaController,
                          obscureText: !_mostrarConfirmaSenha,
                          decoration: InputDecoration(
                            labelText: 'Confirmar Senha',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: corAdmin,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _mostrarConfirmaSenha
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _mostrarConfirmaSenha =
                                      !_mostrarConfirmaSenha;
                                });
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v!.isEmpty) return 'Confirme sua senha';
                            if (v != _senhaController.text) {
                              return 'As senhas não coincidem';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        /// Código de segurança da empresa
                        TextFormField(
                          controller: _codigoSegurancaController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Código de Segurança da Empresa',
                            prefixIcon: Icon(Icons.vpn_key, color: corAdmin),
                          ),
                          validator: (v) =>
                              v != '123456' ? 'Código incorreto' : null,
                        ),

                        const Spacer(),

                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: corAdmin,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                  ),
                                  onPressed: _cadastrarAdmin,
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
