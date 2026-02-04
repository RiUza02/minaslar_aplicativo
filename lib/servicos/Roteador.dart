import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../telas/homeUsuario/HomeUsuario.dart';
import '../telas/homeAdmin/HomeAdmin.dart';
import '../telas/criarConta/Login.dart';

class Roteador extends StatelessWidget {
  const Roteador({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        // 1. Se não tem sessão, vai para Login
        if (session == null) {
          return const Login();
        }

        // 2. Se tem sessão, verifica a role nos metadados (SEM AWAIT)
        // Isso assume que você configurou uma Trigger no Supabase para injetar
        // 'role': 'admin' dentro de app_metadata ou user_metadata
        final metadata = session.user.appMetadata; // ou userMetadata
        final bool isAdmin =
            metadata['role'] == 'admin' || metadata['admin'] == true;

        if (isAdmin) {
          return const HomeAdmin();
        }

        return const HomeUsuario();
      },
    );
  }
}
