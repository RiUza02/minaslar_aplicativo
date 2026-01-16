import 'package:flutter/material.dart';
import '../servicos/autenticacao.dart';

class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  // Chave para validar o formulário
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar o texto dos campos
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _isLoading = false; // Controle da animação de carregamento
  final AuthService _authService = AuthService();

  Future<void> _cadastrar() async {
    // 1. Valida se os campos estão preenchidos corretamente
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 2. Envia para o Firebase (Força isAdmin = FALSE para usuários comuns)
      String? erro = await _authService.cadastrarUsuario(
        nome: _nomeController.text,
        email: _emailController.text,
        password: _senhaController.text,
        isAdmin: false, // <--- Define que NÃO é admin
      );

      setState(() => _isLoading = false);

      // 3. Verifica sucesso ou erro
      if (erro == null) {
        // Sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
          );
          Navigator.pop(context); // Volta para o Login
        }
      } else {
        // Erro
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
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Vincula a chave ao formulário
          child: Column(
            children: [
              // --- NOME ---
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome Completo'),
                validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 10),

              // --- E-MAIL ---
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress, // Teclado com @
                validator: (v) => !v!.contains('@') ? 'E-mail inválido' : null,
              ),
              const SizedBox(height: 10),

              // --- SENHA ---
              TextFormField(
                controller: _senhaController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true, // Esconde a senha
                validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 20),

              // --- BOTÃO ---
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _cadastrar,
                      child: const Text('CRIAR CONTA'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
