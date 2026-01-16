import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- IMPORTANTE: Adicionado
import '../../servicos/autenticacao.dart';
import 'confirmacaoEmail.dart'; // Certifique-se que o nome do arquivo está correto

class CadastroAdminScreen extends StatefulWidget {
  const CadastroAdminScreen({super.key});

  @override
  State<CadastroAdminScreen> createState() => _CadastroAdminScreenState();
}

class _CadastroAdminScreenState extends State<CadastroAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();

  // Código de segurança para admins
  final _codigoSegurancaController = TextEditingController();

  bool _isLoading = false;
  bool _senhaValida = false;

  final AuthService _authService = AuthService();

  Future<void> _cadastrarAdmin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 1. Cria o usuário no Firebase Auth (apenas Auth)
      String? erro = await _authService.cadastrarUsuario(
        email: _emailController.text.trim(),
        password: _senhaController.text,
        // Nota: Nome e isAdmin não são enviados aqui, pois o novo AuthService
        // separa a criação do Auth do salvamento no Firestore.
      );

      setState(() => _isLoading = false);

      if (erro == null) {
        if (mounted) {
          // ====================================================
          // 2. SALVAR BACKUP LOCAL (Para caso o app feche)
          // ====================================================
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('temp_nome', _nomeController.text.trim());
          await prefs.setString('temp_email', _emailController.text.trim());
          await prefs.setBool('temp_isAdmin', true); // É Admin

          // ====================================================
          // 3. IR PARA TELA DE VERIFICAÇÃO
          // ====================================================
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificacaoEmailScreen(
                // Passamos os dados para uso imediato
                emailUsuario: _emailController.text.trim(),
                nomeUsuario: _nomeController.text.trim(),
                isAdmin: true,
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
                            labelText: 'Nome do Administrador',
                            prefixIcon: Icon(Icons.person, color: corAdmin),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Informe o nome' : null,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-mail Corporativo',
                            prefixIcon: Icon(Icons.email, color: corAdmin),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              !v!.contains('@') ? 'E-mail inválido' : null,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _senhaController,
                          decoration: const InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: Icon(Icons.lock, color: corAdmin),
                          ),
                          obscureText: true,
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

                        // Feedback Visual da Senha
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
                          decoration: const InputDecoration(
                            labelText: 'Confirmar Senha',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: corAdmin,
                            ),
                          ),
                          obscureText: true,
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
