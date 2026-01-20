import 'package:flutter/material.dart';
import '../../servicos/autenticacao.dart';

class HomeUsuario extends StatefulWidget {
  const HomeUsuario({super.key});

  @override
  State<HomeUsuario> createState() => _HomeUsuarioState();
}

class _HomeUsuarioState extends State<HomeUsuario> {
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
