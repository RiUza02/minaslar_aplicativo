import 'package:flutter/material.dart';
import '../../servicos/autenticacao.dart';

class HomeUsuarioScreen extends StatefulWidget {
  const HomeUsuarioScreen({super.key});

  @override
  State<HomeUsuarioScreen> createState() => _HomeUsuarioScreenState();
}

class _HomeUsuarioScreenState extends State<HomeUsuarioScreen> {
  // REMOVIDO: O método initState com a verificação de segurança.
  // Não precisamos mais checar nada ao abrir a tela.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Área do Usuário"),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => AuthService().deslogar(),
          ),
        ],
      ),
      body: const Center(
        child: Text("Bem-vindo! Verificação de e-mail desativada."),
      ),
    );
  }
}
