import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- IMPORTANTE: Adicionado
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
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();

  bool _isLoading = false;
  bool _senhaValida = false;

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
        // Nota: 'nome' e 'isAdmin' não são enviados aqui pois serão salvos
        // no Firestore apenas após a validação do e-mail.
      );

      setState(() => _isLoading = false);

      if (erro == null) {
        if (mounted) {
          // ====================================================
          // 2. SALVAR BACKUP LOCAL (Para caso o app feche)
          // ====================================================
          // Salvamos o nome e o tipo de usuário (comum = false)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('temp_nome', _nomeController.text.trim());
          await prefs.setString('temp_email', _emailController.text.trim());
          await prefs.setBool('temp_isAdmin', false); // <--- Usuário Comum

          // ====================================================
          // 3. IR PARA TELA DE VERIFICAÇÃO
          // ====================================================
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificacaoEmailScreen(
                // Passamos os dados para uso imediato (sem precisar ler do disco agora)
                emailUsuario: _emailController.text.trim(),
                nomeUsuario: _nomeController.text.trim(),
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

                        // Senha
                        TextFormField(
                          controller: _senhaController,
                          decoration: const InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: Icon(Icons.lock, color: corPrimaria),
                          ),
                          obscureText: true,
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

                        // Confirmar Senha
                        TextFormField(
                          controller: _confirmaSenhaController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar Senha',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: corPrimaria,
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
