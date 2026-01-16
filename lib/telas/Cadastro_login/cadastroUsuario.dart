import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Necessário para pegar o UID
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../servicos/autenticacao.dart';

class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();

  final maskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _isLoading = false;
  bool _obscureSenha = true;
  bool _obscureConfirma = true;
  bool _senhaValida = false;
  bool _telefoneValido = false;

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

      if (erro == null) {
        // Sucesso no Auth!
        try {
          User? user = FirebaseAuth.instance.currentUser;

          if (user != null) {
            // 2. SALVAR NO FIRESTORE AGORA
            String? erroFirestore = await _authService.salvarDadosNoFirestore(
              uid: user.uid,
              nome: _nomeController.text.trim(),
              email: _emailController.text.trim(),
              telefone: _telefoneController.text.trim(),
              isAdmin: false, // Usuário Comum
            );

            if (erroFirestore == null) {
              if (mounted) {
                // 3. IR DIRETO PARA HOME (Remove histórico anterior)
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/home', (route) => false);
              }
            } else {
              throw erroFirestore;
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Erro ao salvar dados: $e"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Erro Auth
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(erro), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... Layout igual ao anterior, sem mudanças visuais
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
                        TextFormField(
                          controller: _telefoneController,
                          inputFormatters: [maskFormatter],
                          decoration: const InputDecoration(
                            labelText: 'Telefone / Celular',
                            prefixIcon: Icon(Icons.phone, color: corPrimaria),
                            hintText: '(32) 12345-6789',
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            setState(() {
                              _telefoneValido =
                                  maskFormatter.getUnmaskedText().length >= 11;
                            });
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Informe o telefone';
                            if (maskFormatter.getUnmaskedText().length < 11) {
                              return 'Telefone incompleto';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
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
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: corPrimaria,
                            ),
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
