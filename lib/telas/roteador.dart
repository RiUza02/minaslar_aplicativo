import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../servicos/autenticacao.dart';
import 'home/homeUsuario.dart';
import 'home/homeAdmin.dart';
import 'login.dart';

class RoteadorTela extends StatelessWidget {
  const RoteadorTela({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Carregando...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Se tem usuário logado
        if (snapshot.hasData && snapshot.data != null) {
          // REMOVIDO: A checagem de emailVerified e o user.reload()

          // Vai direto verificar se é Admin
          return FutureBuilder<bool>(
            future: AuthService().isUsuarioAdmin(),
            builder: (context, snapshotAdmin) {
              if (snapshotAdmin.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final bool isAdmin = snapshotAdmin.data ?? false;

              if (isAdmin) {
                return const HomeAdminScreen();
              } else {
                return const HomeUsuarioScreen();
              }
            },
          );
        } else {
          // 3. Se não tem usuário, manda pro Login
          return const LoginScreen();
        }
      },
    );
  }
}
