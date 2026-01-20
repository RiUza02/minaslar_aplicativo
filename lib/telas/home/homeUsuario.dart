import 'package:flutter/material.dart';
import '../../servicos/autenticacao.dart';

/// Tela inicial da área do usuário logado
class HomeUsuario extends StatefulWidget {
  const HomeUsuario({super.key});

  @override
  State<HomeUsuario> createState() => _HomeUsuarioState();
}

class _HomeUsuarioState extends State<HomeUsuario> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Área do Usuário"),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Realiza o logout através do serviço de autenticação
              AuthService().deslogar();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text("Bem-vindo! Verificação de e-mail desativada."),
      ),
    );
  }
}
