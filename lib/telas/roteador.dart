import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../servicos/autenticacao.dart';
import 'home/homeUsuario.dart';
import 'home/homeAdmin.dart';
import 'login.dart'; // Importe sua tela de login aqui

class RoteadorTela extends StatelessWidget {
  const RoteadorTela({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Monitora se o usuário está logado ou deslogado em tempo real
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Se estiver carregando o status do Auth...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se tem usuário logado (snapshot.hasData)
        if (snapshot.hasData) {
          // 2. Agora precisamos descobrir SE ele é Admin ou não
          return FutureBuilder<bool>(
            future: AuthService().isUsuarioAdmin(), // Seu método do AuthService
            builder: (context, snapshotAdmin) {
              // Enquanto busca no banco de dados...
              if (snapshotAdmin.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Verificando permissões..."),
                      ],
                    ),
                  ),
                );
              }

              // Se deu erro ou não retornou dados, joga pra usuário comum por segurança
              bool isAdmin = snapshotAdmin.data ?? false;

              // 3. DECISÃO FINAL: Qual tela mostrar?
              if (isAdmin) {
                return const HomeAdminScreen();
              } else {
                return const HomeUsuarioScreen();
              }
            },
          );
        } else {
          // Se não tem usuário logado, manda pro Login
          return const LoginScreen();
        }
      },
    );
  }
}
