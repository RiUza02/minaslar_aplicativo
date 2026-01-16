import 'package:flutter/material.dart';
import '../../servicos/autenticacao.dart';

class HomeUsuarioScreen extends StatelessWidget {
  const HomeUsuarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Área do Usuário"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              AuthService().deslogar();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text("Bem-vindo, Usuário!", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
