import 'package:flutter/material.dart';
import 'CadastroUsuario.dart';
import 'CadastroAdmin.dart';

/// Tela responsável por permitir a escolha
/// do tipo de conta a ser criada
class Cadastro extends StatelessWidget {
  const Cadastro({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Spacer(),

            /// Título principal da tela
            const Text(
              'Escolha o tipo de conta',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // BOTÃO: CADASTRO DE CONTA ADMINISTRADOR
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text(
                  'Administrador',
                  style: TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Navega para a tela de cadastro de administrador
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CadastroAdminScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // BOTÃO: CADASTRO DE CONTA DE USUÁRIO COMUM
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text(
                  'Usuário Comum',
                  style: TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Navega para a tela de cadastro de usuário comum
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CadastroUsuarioScreen(),
                    ),
                  );
                },
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
