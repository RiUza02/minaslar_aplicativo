import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../servicos/autenticacao.dart';

class CadastroAdminScreen extends StatefulWidget {
  const CadastroAdminScreen({super.key});

  @override
  State<CadastroAdminScreen> createState() => _CadastroAdminScreenState();
}

class _CadastroAdminScreenState extends State<CadastroAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();
  final _codigoSegurancaController = TextEditingController();

  final maskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _isLoading = false;
  bool _senhaValida = false;
  bool _telefoneValido = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmaSenha = false;

  final AuthService _authService = AuthService();

  // ==========================================
  // FUNÇÃO CORRIGIDA PARA SUPABASE
  // ==========================================
  Future<void> _cadastrarAdmin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Chamamos o método único que cria o login E salva os dados na tabela
      String? erro = await _authService.cadastrarUsuario(
        email: _emailController.text.trim(),
        password: _senhaController.text,
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
        isAdmin: true, // IMPORTANTE: Passamos TRUE pois é tela de Admin
      );

      if (mounted) setState(() => _isLoading = false);

      if (erro == null) {
        // Sucesso!
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Administrador criado com sucesso!"),
              backgroundColor: Colors.green,
            ),
          );

          // Redireciona para a raiz (RoteadorTelas), que vai detectar o login e mandar para a Home
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        // Erro
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
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email, color: corAdmin),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              !v!.contains('@') ? 'E-mail inválido' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _telefoneController,
                          inputFormatters: [maskFormatter],
                          decoration: const InputDecoration(
                            labelText: 'Telefone / Celular',
                            prefixIcon: Icon(Icons.phone, color: corAdmin),
                            hintText: '(32) 12345-6789',
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (valor) {
                            setState(() {
                              _telefoneValido = valor.length >= 15;
                            });
                          },
                          validator: (v) {
                            if (v!.isEmpty) return 'Informe o telefone';
                            if (v.length < 15) return 'Telefone incompleto';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
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
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _mostrarSenha = !_mostrarSenha;
                                });
                              },
                            ),
                          ),
                          onChanged: (valor) {
                            setState(() {
                              _senhaValida = valor.length >= 6;
                            });
                          },
                          validator: (v) => v!.length < 6
                              ? 'A senha deve ter no mínimo 6 caracteres'
                              : null,
                        ),
                        const SizedBox(height: 8),
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
                        TextFormField(
                          controller: _confirmaSenhaController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                color: Colors.grey,
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
                        TextFormField(
                          controller: _codigoSegurancaController,
                          decoration: const InputDecoration(
                            labelText: 'Código de Segurança da Empresa',
                            prefixIcon: Icon(Icons.vpn_key, color: corAdmin),
                          ),
                          obscureText: true,
                          validator: (v) =>
                              v != '123456' ? 'Código incorreto' : null,
                        ),
                        const Spacer(),
                        const SizedBox(height: 20),
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
