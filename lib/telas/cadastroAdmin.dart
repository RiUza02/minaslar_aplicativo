import 'package:flutter/material.dart';
import '../servicos/autenticacao.dart';

class CadastroAdminScreen extends StatefulWidget {
  const CadastroAdminScreen({super.key});

  @override
  State<CadastroAdminScreen> createState() => _CadastroAdminScreenState();
}

class _CadastroAdminScreenState extends State<CadastroAdminScreen> {
  // Chave global para identificar e validar o formulário
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _codigoAcessoController = TextEditingController();

  bool _isLoading = false;

  // Variável para controlar a cor do texto da senha em tempo real
  bool _senhaValida = false;

  final AuthService _authService = AuthService();

  Future<void> _cadastrarAdmin() async {
    if (_formKey.currentState!.validate()) {
      // Trava de Segurança
      if (_codigoAcessoController.text != '123') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código de acesso incorreto!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      String? erro = await _authService.cadastrarUsuario(
        nome: _nomeController.text,
        email: _emailController.text,
        password: _senhaController.text,
        isAdmin: true,
      );

      setState(() => _isLoading = false);

      if (erro == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Administrador criado com sucesso!')),
          );
          Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Administrador'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // --- NOME ---
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(labelText: 'Nome Completo'),
                  validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 50),

                // --- E-MAIL ---
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      !v!.contains('@') ? 'E-mail inválido' : null,
                ),
                const SizedBox(height: 50),

                // --- SENHA ---
                TextFormField(
                  controller: _senhaController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  // Verifica a cada letra digitada
                  onChanged: (valor) {
                    setState(() {
                      _senhaValida = valor.length >= 6;
                    });
                  },
                  // Mantemos o validator para bloquear o envio se estiver errado
                  validator: (v) => v!.length < 6
                      ? 'A senha não cumpre os requisitos minimos'
                      : null,
                ),
                const SizedBox(height: 50),

                // --- FEEDBACK VISUAL DA SENHA (Novo) ---
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        _senhaValida ? Icons.check_circle : Icons.cancel,
                        color: _senhaValida ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Mínimo de 6 caracteres",
                        style: TextStyle(
                          color: _senhaValida ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- CÓDIGO DE SEGURANÇA ---
                TextFormField(
                  controller: _codigoAcessoController,
                  decoration: const InputDecoration(
                    labelText: 'Código de Acesso da Empresa',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  validator: (v) =>
                      v!.isEmpty ? 'Código de segurança incorreto' : null,
                ),
                const SizedBox(height: 20),

                // --- BOTÃO ---
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _cadastrarAdmin,
                        child: const Text('CRIAR ADMIN'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
