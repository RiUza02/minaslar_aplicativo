import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ⚠️ Import necessário
import '../../servicos/autenticacao.dart';
import 'home/homeUsuario.dart';
import 'home/homeAdmin.dart';
import 'login.dart';

class RoteadorTela extends StatelessWidget {
  const RoteadorTela({super.key});

  @override
  Widget build(BuildContext context) {
    // ⚠️ MUDANÇA 1: Stream do Supabase (AuthState), não User
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 1. Carregando...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ⚠️ MUDANÇA 2: Verificamos a "session" (sessão)
        final session = snapshot.data?.session;

        // 2. Se tem sessão válida (Usuário logado)
        if (session != null) {
          // Vai verificar se é Admin
          return FutureBuilder<bool>(
            future: AuthService().isUsuarioAdmin(),
            builder: (context, snapshotAdmin) {
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

              final bool isAdmin = snapshotAdmin.data ?? false;

              if (isAdmin) {
                return const HomeAdminScreen();
              } else {
                return const HomeUsuarioScreen();
              }
            },
          );
        } else {
          // 3. Se a sessão é nula, manda pro Login
          return const LoginScreen();
        }
      },
    );
  }
}
