import 'package:flutter/material.dart';
import 'Cadastro_login/cadastroUsuario.dart';
import 'Cadastro_login/cadastroAdmin.dart';

class EscolhaTipoCadastroScreen extends StatelessWidget {
  const EscolhaTipoCadastroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Spacer(),

            const Text(
              'Escolha o tipo de conta',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            // =========================
            // CONTA ADMINISTRADOR
            // =========================
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text(
                  'Administrador',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
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

            // =========================
            // CONTA USUÁRIO COMUM
            // =========================
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text(
                  'Usuário Comum',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
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
